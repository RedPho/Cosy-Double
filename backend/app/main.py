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
                Room(name="The Focus Room", category="Focus"),
            ]
            session.add_all(default_rooms)
            print("Seeded default room.")

        # Seed Shop Items if empty
        item_stmt = select(Item)
        items_res = await session.execute(item_stmt)
        if not items_res.scalars().all():
            default_items = [
                # T0: Free
                Item(name="The Sunrise Studio", cost_leaves=0, price_usd=0.0, is_premium=False, image_url="sunrise_studio", category="theme"),
                # T1: Leaves-only (cheap, grindable)
                Item(name="The Golden Hour", cost_leaves=15, price_usd=0.0, is_premium=False, image_url="golden_hour", category="theme"),
                Item(name="The Matcha Morning", cost_leaves=20, price_usd=0.0, is_premium=False, image_url="matcha_morning", category="theme"),
                Item(name="The Rainy Window", cost_leaves=25, price_usd=0.0, is_premium=False, image_url="rainy_window", category="theme"),
                # T2: Dual currency (🍃 OR $)
                Item(name="The Deep Work Zone", cost_leaves=30, price_usd=0.99, is_premium=False, image_url="deep_work_zone", category="theme"),
                Item(name="The Dusty Vinyl", cost_leaves=35, price_usd=0.99, is_premium=False, image_url="dusty_vinyl", category="theme"),
                Item(name="The Botanical Library", cost_leaves=40, price_usd=0.99, is_premium=False, image_url="botanical_library", category="theme"),
                Item(name="The Library Archive", cost_leaves=45, price_usd=1.49, is_premium=False, image_url="library_archive", category="theme"),
                Item(name="The Lavender Fog", cost_leaves=50, price_usd=1.49, is_premium=False, image_url="lavender_fog", category="theme"),
                Item(name="The Arctic Cabin", cost_leaves=60, price_usd=1.49, is_premium=False, image_url="arctic_cabin", category="theme"),
                # T3: Premium USD-only
                Item(name="The Rose Quartz", cost_leaves=0, price_usd=1.49, is_premium=True, image_url="rose_quartz", category="theme"),
                Item(name="The Moonlight Garden", cost_leaves=0, price_usd=1.99, is_premium=True, image_url="moonlight_garden", category="theme"),
                Item(name="The Desert Oasis", cost_leaves=0, price_usd=2.99, is_premium=True, image_url="desert_oasis", category="theme"),
                Item(name="The Neon Tokyo", cost_leaves=0, price_usd=3.99, is_premium=True, image_url="neon_tokyo", category="theme"),
                Item(name="The Midnight Ink", cost_leaves=0, price_usd=4.99, is_premium=True, image_url="midnight_ink", category="theme"),
            ]
            session.add_all(default_items)
            print("Seeded 15 curated Color Themes (T0 free / T1 leaves / T2 dual / T3 premium).")

        await session.commit()
