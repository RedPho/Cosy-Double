from fastapi import APIRouter, Depends, HTTPException, Request, Header, status
from sqlmodel import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import stripe
from pydantic import BaseModel

from backend.app.db import get_db
from backend.app.models import Item, Inventory, User
from backend.app.auth import get_current_user
from backend.app.config import settings

# Initialize Stripe
stripe.api_key = settings.STRIPE_SECRET_KEY

router = APIRouter(prefix="/shop", tags=["shop"])

class PurchaseRequest(BaseModel):
    item_id: int

class PaymentIntentRequest(BaseModel):
    item_id: int

class PaymentIntentResponse(BaseModel):
    payment_intent_client_secret: str
    publishable_key: str
    amount_cents: int

class PurchaseResponse(BaseModel):
    success: bool
    leaves_balance: int
    inventory_id: int

class ItemOut(BaseModel):
    id: int
    name: str
    cost_leaves: int
    price_usd: float
    is_premium: bool
    image_url: str
    category: str

@router.get("/items", response_model=List[ItemOut])
async def get_shop_items(db: AsyncSession = Depends(get_db)):
    stmt = select(Item)
    res = await db.execute(stmt)
    return res.scalars().all()

@router.post("/purchase", response_model=PurchaseResponse)
async def purchase_with_leaves(data: PurchaseRequest, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    # Fetch item
    stmt_item = select(Item).where(Item.id == data.item_id)
    res_item = await db.execute(stmt_item)
    item = res_item.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
        
    if item.is_premium:
        raise HTTPException(status_code=400, detail="Premium items must be purchased with USD")
        
    if current_user.leaves_balance < item.cost_leaves:
        raise HTTPException(status_code=400, detail="Insufficient leaves balance")
        
    # Check if user already owns it (optional: decoration items can be purchased multiple times, background only once)
    if item.category == "background":
        stmt_own = select(Inventory).where(and_(Inventory.user_id == current_user.id, Inventory.item_id == item.id))
        res_own = await db.execute(stmt_own)
        if res_own.scalars().first():
            raise HTTPException(status_code=400, detail="You already own this background")
            
    # Deduct leaves and add to inventory
    current_user.leaves_balance -= item.cost_leaves
    inventory = Inventory(
        user_id=current_user.id,
        item_id=item.id,
        x_pos=0.5, # default center placement
        y_pos=0.5,
        is_placed=False
    )
    
    db.add(current_user)
    db.add(inventory)
    await db.commit()
    await db.refresh(inventory)
    
    return PurchaseResponse(
        success=True,
        leaves_balance=current_user.leaves_balance,
        inventory_id=inventory.id
    )

@router.post("/stripe-payment-intent", response_model=PaymentIntentResponse)
async def create_payment_intent(data: PaymentIntentRequest, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    stmt_item = select(Item).where(Item.id == data.item_id)
    res_item = await db.execute(stmt_item)
    item = res_item.scalar_one_or_none()
    if not item or not item.is_premium:
        raise HTTPException(status_code=400, detail="Item not found or is not premium")
        
    # Check ownership
    stmt_own = select(Inventory).where(and_(Inventory.user_id == current_user.id, Inventory.item_id == item.id))
    res_own = await db.execute(stmt_own)
    if res_own.scalars().first():
        raise HTTPException(status_code=400, detail="You already own this item")
        
    amount_cents = int(item.price_usd * 100)
    
    try:
        # Create a PaymentIntent with user & item metadata
        intent = stripe.PaymentIntent.create(
            amount=amount_cents,
            currency="usd",
            metadata={
                "user_id": str(current_user.id),
                "item_id": str(item.id)
            },
            automatic_payment_methods={"enabled": True}
        )
        return PaymentIntentResponse(
            payment_intent_client_secret=intent.client_secret,
            publishable_key=settings.STRIPE_PUBLISHABLE_KEY,
            amount_cents=amount_cents
        )
    except Exception as e:
        # If API keys are mock/invalid, return a mock client secret for frontend preview
        if "mock" in settings.STRIPE_SECRET_KEY or "test_mock" in settings.STRIPE_SECRET_KEY:
            mock_secret = f"pi_mock_secret_{data.item_id}_{current_user.id}"
            return PaymentIntentResponse(
                payment_intent_client_secret=mock_secret,
                publishable_key=settings.STRIPE_PUBLISHABLE_KEY,
                amount_cents=amount_cents
            )
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/stripe-webhook")
async def stripe_webhook(request: Request, stripe_signature: Optional[str] = Header(None), db: AsyncSession = Depends(get_db)):
    payload = await request.body()
    event = None

    try:
        # Verify webhook signature if secret is provided
        if settings.STRIPE_WEBHOOK_SECRET and stripe_signature and "mock" not in settings.STRIPE_WEBHOOK_SECRET:
            event = stripe.Webhook.construct_event(
                payload, stripe_signature, settings.STRIPE_WEBHOOK_SECRET
            )
        else:
            # If mock, load JSON directly
            import json
            event = json.loads(payload)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid webhook request: {e}")

    # Process successful payment intent
    event_type = event.get("type") if isinstance(event, dict) else event.type
    event_data = event.get("data") if isinstance(event, dict) else event.data
    
    if event_type == "payment_intent.succeeded":
        payment_intent = event_data.get("object") if isinstance(event_data, dict) else event_data.object
        metadata = payment_intent.get("metadata", {})
        user_id = int(metadata.get("user_id"))
        item_id = int(metadata.get("item_id"))
        
        # Verify item exists
        stmt_item = select(Item).where(Item.id == item_id)
        res_item = await db.execute(stmt_item)
        item = res_item.scalar_one_or_none()
        
        if item:
            # Check if already owned
            stmt_own = select(Inventory).where(and_(Inventory.user_id == user_id, Inventory.item_id == item_id))
            res_own = await db.execute(stmt_own)
            
            if not res_own.scalars().first():
                # Add to user inventory
                inv = Inventory(
                    user_id=user_id,
                    item_id=item_id,
                    x_pos=0.5,
                    y_pos=0.5,
                    is_placed=False
                )
                db.add(inv)
                await db.commit()
                print(f"Provisioned item {item.name} for user {user_id} via Stripe.")
                
    return {"status": "success"}
