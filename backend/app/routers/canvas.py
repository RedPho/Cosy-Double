from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from pydantic import BaseModel

from backend.app.db import get_db
from backend.app.models import Inventory, Item, User
from backend.app.auth import get_current_user

router = APIRouter(prefix="/users/oasis", tags=["canvas"])

# Response/Request schemas
class InventoryItemOut(BaseModel):
    id: int  # inventory_id
    item_id: int
    name: str
    image_url: str
    category: str
    x_pos: float
    y_pos: float
    is_placed: bool

class ItemLayoutUpdate(BaseModel):
    inventory_id: int
    x_pos: float
    y_pos: float
    is_placed: bool

class LayoutUpdateResponse(BaseModel):
    success: bool
    updated_count: int

@router.get("/items", response_model=List[InventoryItemOut])
async def get_oasis_items(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    # Join Inventory and Item to fetch full details of user owned items
    stmt = select(Inventory, Item).join(Item).where(Inventory.user_id == current_user.id)
    res = await db.execute(stmt)
    results = res.all()
    
    out_items = []
    for inv, item in results:
        out_items.append(
            InventoryItemOut(
                id=inv.id,
                item_id=item.id,
                name=item.name,
                image_url=item.image_url,
                category=item.category,
                x_pos=inv.x_pos,
                y_pos=inv.y_pos,
                is_placed=inv.is_placed
            )
        )
    return out_items

@router.put("/items", response_model=LayoutUpdateResponse)
async def update_item_layout(updates: List[ItemLayoutUpdate], db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    updated_count = 0
    for update in updates:
        stmt = select(Inventory).where(
            and_(
                Inventory.id == update.inventory_id,
                Inventory.user_id == current_user.id
            )
        )
        res = await db.execute(stmt)
        inv = res.scalar_one_or_none()
        
        if inv:
            inv.x_pos = update.x_pos
            inv.y_pos = update.y_pos
            inv.is_placed = update.is_placed
            db.add(inv)
            updated_count += 1
            
    if updated_count > 0:
        await db.commit()
        
    return LayoutUpdateResponse(
        success=True,
        updated_count=updated_count
    )
