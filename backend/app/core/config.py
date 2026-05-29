from functools import lru_cache
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
   
    DATABASE_URL: str = "postgresql+asyncpg://postgres:password@localhost:5432/safemind"

    
    SUPABASE_URL: str = ""
    SUPABASE_KEY: str = ""
    SUPABASE_SERVICE_KEY: str = ""

    
    SECRET_KEY: str = "changez-moi-en-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24h

    
    AVATAR_BUCKET: str = "avatars"
    MEDICINE_BUCKET: str = "medicines_bucket"

    
    APP_NAME: str = "SafeMind"
    DEBUG: bool = False

    class Config:
        env_file = ".env"
        extra = "ignore"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()