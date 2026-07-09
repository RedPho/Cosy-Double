import os

class Settings:
    # Database configuration
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", 
        "postgresql+asyncpg://cozy_user:cozy_password@localhost:5432/cozy_double"
    )
    
    # Synchronous DB URL for Alembic
    SYNC_DATABASE_URL: str = os.getenv(
        "SYNC_DATABASE_URL",
        "postgresql://cozy_user:cozy_password@localhost:5432/cozy_double"
    )

    # JWT configurations
    JWT_SECRET: str = os.getenv("JWT_SECRET", "cozy_double_super_secret_key_change_me")
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days for stateless mobile focus

settings = Settings()
