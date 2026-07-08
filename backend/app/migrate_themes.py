import asyncio
from sqlmodel import select, delete
from backend.app.db import async_session_maker
from backend.app.models import Item, Inventory

async def migrate():
    print("🔄 Running Color Themes Seeding Migration...")
    async with async_session_maker() as session:
        # Clear existing cosmetics and ownership records
        await session.execute(delete(Inventory))
        await session.execute(delete(Item))
        print("🗑️ Cleared old items and user inventories.")
        
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
        await session.commit()
        print("🌱 Seeded 5 default Color Themes successfully.")

if __name__ == "__main__":
    asyncio.run(migrate())
