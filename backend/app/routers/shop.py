from fastapi import APIRouter, Depends, HTTPException, Request, Header, status
from sqlmodel import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from pydantic import BaseModel

from backend.app.db import get_db
from backend.app.models import Item, Inventory, User
from backend.app.auth import get_current_user
from backend.app.config import settings

router = APIRouter(prefix="/shop", tags=["shop"])

class PurchaseRequest(BaseModel):
    item_id: int

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
    stmt = select(Item).where(Item.cost_leaves > 0)
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
