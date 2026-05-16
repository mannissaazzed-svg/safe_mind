from fastapi import FastAPI
from app.routers.users_router import router

app = FastAPI(
    title="SafeMind API",
    version="1.0.0"
)

@app.get("/")
def root():
    return {"message": "SafeMind Backend Running"}

app.include_router(router)