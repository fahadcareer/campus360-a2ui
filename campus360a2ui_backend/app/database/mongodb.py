from motor.motor_asyncio import AsyncIOMotorClient
import os
from dotenv import load_dotenv

load_dotenv()

class Database:
    client: AsyncIOMotorClient = None
    db = None

db_instance = Database()

async def init_db():
    mongodb_uri = os.getenv("MONGODB_URI", "mongodb://localhost:27017/campus360")
    # Parse DB name from URI or default to campus360
    db_name = mongodb_uri.split('/')[-1].split('?')[0]
    if not db_name:
        db_name = "campus360"
        
    db_instance.client = AsyncIOMotorClient(mongodb_uri)
    db_instance.db = db_instance.client[db_name]
    print(f"Connected to MongoDB database: {db_name}")

async def close_db():
    if db_instance.client:
        db_instance.client.close()
        print("MongoDB connection closed.")

def get_db():
    if db_instance.db is None:
        raise Exception("Database is not initialized")
    return db_instance.db
