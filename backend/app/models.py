from typing import Optional, List
from sqlmodel import SQLModel, Field, Relationship
from datetime import datetime

# User model
class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(unique=True, index=True)
    hashed_password: str
    leaves_balance: int = Field(default=0)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    sessions: List["Session"] = Relationship(back_populates="user")
    tasks: List["Task"] = Relationship(back_populates="user")
    inventories: List["Inventory"] = Relationship(back_populates="user")

# Room model
class Room(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    category: str  # "Deep Work", "Body Doubling", "Casual"
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    sessions: List["Session"] = Relationship(back_populates="room")

# Session model
class Session(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    room_id: int = Field(foreign_key="room.id")
    started_at: datetime = Field(default_factory=datetime.utcnow)
    ended_at: Optional[datetime] = None
    duration_seconds: Optional[int] = Field(default=0)
    leaves_earned: Optional[int] = Field(default=0)
    passive_leaves: Optional[int] = Field(default=0)
    active_leaves: Optional[int] = Field(default=0)
    
    user: User = Relationship(back_populates="sessions")
    room: Room = Relationship(back_populates="sessions")
    tasks: List["Task"] = Relationship(back_populates="session")

# Task model
class Task(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    session_id: Optional[int] = Field(default=None, foreign_key="session.id")
    user_id: int = Field(foreign_key="user.id")
    title: str
    is_completed: bool = Field(default=False)
    is_active: bool = Field(default=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    completed_at: Optional[datetime] = None
    
    user: User = Relationship(back_populates="tasks")
    session: Optional[Session] = Relationship(back_populates="tasks")

# Item model (for Shop)
class Item(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    cost_leaves: int = Field(default=0)  # price in leaves (0 if not purchasable with leaves)
    price_usd: Optional[float] = Field(default=0.0)  # price in USD (0.0 if free/only leaves)
    is_premium: bool = Field(default=False)
    image_url: str
    category: str = Field(default="decoration")  # "decoration", "background", etc.

# Inventory model (User's owned items and their coordinates in Oasis canvas)
class Inventory(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    item_id: int = Field(foreign_key="item.id")
    x_pos: float = Field(default=0.0)  # relative X coordinate (0.0 to 1.0 or pixel offsets)
    y_pos: float = Field(default=0.0)  # relative Y coordinate (0.0 to 1.0 or pixel offsets)
    is_placed: bool = Field(default=False)
    purchased_at: datetime = Field(default_factory=datetime.utcnow)
    
    user: User = Relationship(back_populates="inventories")
    item: Item = Relationship()
