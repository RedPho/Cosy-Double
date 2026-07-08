from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from backend.app.config import settings

# Create async database engine
engine = create_async_engine(
    settings.DATABASE_URL, 
    echo=False, 
    future=True,
    pool_size=20,
    max_overflow=10
)

# Async session factory
async_session_maker = sessionmaker(
    engine, 
    class_=AsyncSession, 
    expire_on_commit=False
)

# Dependency for FastAPI endpoints
async def get_db():
    async with async_session_maker() as session:
        try:
            yield session
        finally:
            await session.close()
