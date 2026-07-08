from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import select
from backend.app.db import engine, async_session_maker
from backend.app.models import Room, Item
from backend.app.routers import auth, rooms, shop, canvas

app = FastAPI(title="Cozy Double API", version="1.0.0")

# CORS middleware configuration to allow Flutter mobile/web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for local dev and Flutter web clients
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(rooms.router)
app.include_router(shop.router)
app.include_router(canvas.router)

@app.get("/")
async def root():
    return {"message": "Welcome to Cozy Double API. Keep focused and cozy! 🍃"}

@app.on_event("startup")
async def on_startup():
    # Database seeding on startup for development convenience
    async with async_session_maker() as session:
        # Seed Rooms if empty
        room_stmt = select(Room)
        rooms_res = await session.execute(room_stmt)
        if not rooms_res.scalars().all():
            default_rooms = [
                Room(name="Deep Work Oasis", category="Deep Work"),
                Room(name="Cozy Library", category="Body Doubling"),
                Room(name="Lo-fi Corner", category="Casual"),
            ]
            session.add_all(default_rooms)
            print("Seeded default rooms.")

        # Seed Shop Items if empty
        item_stmt = select(Item)
        items_res = await session.execute(item_stmt)
        if not items_res.scalars().all():
            default_items = [
                Item(
                    name="Forest Mist Theme", 
                    cost_leaves=50, 
                    price_usd=0.0, 
                    is_premium=False, 
                    image_url="forest_mist",
                    category="theme"
                ),
                Item(
                    name="Warm Sunset Theme", 
                    cost_leaves=15, 
                    price_usd=0.0, 
                    is_premium=False, 
                    image_url="warm_sunset",
                    category="theme"
                ),
                Item(
                    name="Midnight Slate Theme", 
                    cost_leaves=30, 
                    price_usd=0.0, 
                    is_premium=False, 
                    image_url="midnight_slate",
                    category="theme"
                ),
                Item(
                    name="Sweet Apricot Theme", 
                    cost_leaves=0, 
                    price_usd=1.99, 
                    is_premium=True, 
                    image_url="sweet_apricot",
                    category="theme"
                ),
                Item(
                    name="Lavender Dreams Theme", 
                    cost_leaves=0, 
                    price_usd=2.99, 
                    is_premium=True, 
                    image_url="lavender_dreams",
                    category="theme"
                ),
            ]
            session.add_all(default_items)
            print("Seeded default items.")

        await session.commit()
