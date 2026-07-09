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
            # ── TIER 0: Free (always available) ─────────────────────────────
            Item(
                name="The Sunrise Studio",
                cost_leaves=0, price_usd=0.0, is_premium=False,
                image_url="sunrise_studio", category="theme"
            ),

            # ── TIER 1: Leaves-only (cheap, grindable) ──────────────────────
            # Great for new users who want to earn their first theme.
            Item(
                name="The Golden Hour",
                cost_leaves=15, price_usd=0.0, is_premium=False,
                image_url="golden_hour", category="theme"
            ),
            Item(
                name="The Matcha Morning",
                cost_leaves=20, price_usd=0.0, is_premium=False,
                image_url="matcha_morning", category="theme"
            ),
            Item(
                name="The Rainy Window",
                cost_leaves=25, price_usd=0.0, is_premium=False,
                image_url="rainy_window", category="theme"
            ),

            # ── TIER 2: Dual currency (🍃 OR $) ─────────────────────────────
            # Mid-tier themes: users can grind leaves or skip with real money.
            # Keeps monetization open without hard-paywalling.
            Item(
                name="The Deep Work Zone",
                cost_leaves=30, price_usd=0.99, is_premium=False,
                image_url="deep_work_zone", category="theme"
            ),
            Item(
                name="The Dusty Vinyl",
                cost_leaves=35, price_usd=0.99, is_premium=False,
                image_url="dusty_vinyl", category="theme"
            ),
            Item(
                name="The Botanical Library",
                cost_leaves=40, price_usd=0.99, is_premium=False,
                image_url="botanical_library", category="theme"
            ),
            Item(
                name="The Library Archive",
                cost_leaves=45, price_usd=1.49, is_premium=False,
                image_url="library_archive", category="theme"
            ),
            Item(
                name="The Lavender Fog",
                cost_leaves=50, price_usd=1.49, is_premium=False,
                image_url="lavender_fog", category="theme"
            ),
            Item(
                name="The Arctic Cabin",
                cost_leaves=60, price_usd=1.49, is_premium=False,
                image_url="arctic_cabin", category="theme"
            ),

            # ── TIER 3: Premium USD-only ─────────────────────────────────────
            # High-quality, exclusive themes — no leaf path available.
            Item(
                name="The Rose Quartz",
                cost_leaves=0, price_usd=1.49, is_premium=True,
                image_url="rose_quartz", category="theme"
            ),
            Item(
                name="The Moonlight Garden",
                cost_leaves=0, price_usd=1.99, is_premium=True,
                image_url="moonlight_garden", category="theme"
            ),
            Item(
                name="The Desert Oasis",
                cost_leaves=0, price_usd=2.99, is_premium=True,
                image_url="desert_oasis", category="theme"
            ),
            Item(
                name="The Neon Tokyo",
                cost_leaves=0, price_usd=3.99, is_premium=True,
                image_url="neon_tokyo", category="theme"
            ),
            Item(
                name="The Midnight Ink",
                cost_leaves=0, price_usd=4.99, is_premium=True,
                image_url="midnight_ink", category="theme"
            ),
        ]
        session.add_all(default_items)
        await session.commit()
        print("🌱 Seeded 15 curated Color Themes successfully.")
        print("   T0: 1 free | T1: 3 leaves-only | T2: 6 dual-currency | T3: 5 premium USD")

if __name__ == "__main__":
    asyncio.run(migrate())
