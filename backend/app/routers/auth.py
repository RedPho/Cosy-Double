from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional
from pydantic import BaseModel, EmailStr
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession
from backend.app.db import get_db
from backend.app.models import User, Item, Inventory
from backend.app.auth import hash_password, verify_password, create_access_token, get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])

class Token(BaseModel):
    access_token: str
    token_type: str
    leaves_balance: int

class UserOut(BaseModel):
    id: int
    email: Optional[EmailStr] = None
    username: str
    leaves_balance: int

class GuestLoginRequest(BaseModel):
    username: Optional[str] = None

class NicknameUpdate(BaseModel):
    username: str

@router.post("/guest", response_model=Token)
async def guest_login(data: GuestLoginRequest, db: AsyncSession = Depends(get_db)):
    import random
    
    username = data.username.strip() if data.username else None
    
    if not username:
        adjectives = ["Cozy", "Warm", "Focusing", "Silent", "Mindful", "Calm", "Gentle", "Sleepy", "Soft", "Peaceful"]
        nouns = ["Panda", "Koala", "Bear", "Otter", "Fox", "Sloth", "Squirrel", "Hedgehog", "Rabbit", "Deer"]
        username = f"{random.choice(adjectives)}{random.choice(nouns)}{random.randint(100, 999)}"
    else:
        # Check if username exists
        stmt_un = select(User).where(User.username == username)
        res_un = await db.execute(stmt_un)
        if res_un.scalar_one_or_none():
            username = f"{username}_{random.randint(10, 99)}"
            
    # Create Guest User
    new_user = User(
        email=None,
        username=username,
        hashed_password=None,
        leaves_balance=10
    )
    db.add(new_user)
    await db.flush()
    
    # Assign default background naturally
    stmt_item = select(Item).where(Item.image_url == "sunrise_studio")
    res_item = await db.execute(stmt_item)
    default_item = res_item.scalar_one_or_none()
    
    if default_item:
        new_inv = Inventory(
            user_id=new_user.id,
            item_id=default_item.id,
            is_placed=True,
            x_pos=0.0,
            y_pos=0.0
        )
        db.add(new_inv)
        
    await db.commit()
    await db.refresh(new_user)
    
    token = create_access_token(data={"sub": str(new_user.id)})
    return {
        "access_token": token,
        "token_type": "bearer",
        "leaves_balance": new_user.leaves_balance
    }

@router.put("/nickname", response_model=UserOut)
async def update_nickname(
    data: NicknameUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    stmt = select(User).where(User.username == data.username)
    res = await db.execute(stmt)
    if res.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nickname already taken"
        )
    current_user.username = data.username
    await db.commit()
    await db.refresh(current_user)
    return current_user

@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user
