from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession
from backend.app.db import get_db
from backend.app.models import User, Item, Inventory
from backend.app.auth import hash_password, verify_password, create_access_token, get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])

class UserRegister(BaseModel):
    email: EmailStr
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    leaves_balance: int

class UserOut(BaseModel):
    id: int
    email: EmailStr
    leaves_balance: int

@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def register(user_in: UserRegister, db: AsyncSession = Depends(get_db)):
    # Check if user already exists
    stmt = select(User).where(User.email == user_in.email)
    res = await db.execute(stmt)
    if res.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    new_user = User(
        email=user_in.email,
        hashed_password=hash_password(user_in.password),
        leaves_balance=10  # Give 10 initial welcome leaves!
    )
    db.add(new_user)
    await db.flush()  # To get new_user.id
    
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
    return new_user

@router.post("/login", response_model=Token)
async def login(user_in: UserLogin, db: AsyncSession = Depends(get_db)):
    stmt = select(User).where(User.email == user_in.email)
    res = await db.execute(stmt)
    user = res.scalar_one_or_none()
    
    if not user or not verify_password(user_in.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
        
    token = create_access_token(data={"sub": user.email})
    return {
        "access_token": token,
        "token_type": "bearer",
        "leaves_balance": user.leaves_balance
    }

@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user

@router.delete("/delete-account", status_code=status.HTTP_200_OK)
async def delete_account(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from sqlmodel import delete
    from backend.app.models import Inventory, Session, Task
    
    # Delete dependent data
    await db.execute(delete(Inventory).where(Inventory.user_id == current_user.id))
    await db.execute(delete(Task).where(Task.user_id == current_user.id))
    await db.execute(delete(Session).where(Session.user_id == current_user.id))
    # Delete user
    await db.delete(current_user)
    await db.commit()
    return {"message": "Account successfully deleted"}
