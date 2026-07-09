import asyncio
from sqlmodel import select
from backend.app.db import async_session_maker
from backend.app.models import User, Item, Inventory

async def run():
    async with async_session_maker() as session:
        stmt_item = select(Item).where(Item.image_url == "sunrise_studio")
        res_item = await session.execute(stmt_item)
        default_item = res_item.scalar_one_or_none()
        
        if not default_item:
            print("Default theme not found")
            return
            
        stmt_users = select(User)
        res_users = await session.execute(stmt_users)
        users = res_users.scalars().all()
        
        for u in users:
            stmt_inv = select(Inventory).where(Inventory.user_id == u.id, Inventory.item_id == default_item.id)
            res_inv = await session.execute(stmt_inv)
            if not res_inv.scalar_one_or_none():
                new_inv = Inventory(
                    user_id=u.id,
                    item_id=default_item.id,
                    is_placed=True,
                    x_pos=0.0,
                    y_pos=0.0
                )
                session.add(new_inv)
                print(f"Assigned to user {u.email}")
        
        await session.commit()

if __name__ == "__main__":
    asyncio.run(run())
