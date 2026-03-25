from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field
from typing import List, Optional
from datetime import datetime
from app.database.mongodb import get_db
from app.models.user import UserInDB, PyObjectId
from app.api.auth import get_current_user
from bson import ObjectId

router = APIRouter()

class NotificationBase(BaseModel):
    title: str
    message: str
    type: str = "info"
    read: bool = False
    userId: PyObjectId
    schoolId: Optional[PyObjectId] = None
    createdAt: Optional[datetime] = None

    model_config = ConfigDict(arbitrary_types_allowed=True, populate_by_name=True)

class NotificationResponse(NotificationBase):
    id: str
    userId: str
    schoolId: Optional[str] = None

    @classmethod
    def from_mongo(cls, mongo_doc):
        if not mongo_doc: return None
        doc = dict(mongo_doc)
        if "_id" in doc: doc["id"] = str(doc.pop("_id"))
        if "userId" in doc and doc["userId"]: doc["userId"] = str(doc["userId"])
        if "schoolId" in doc and doc["schoolId"]: doc["schoolId"] = str(doc["schoolId"])
        return cls(**doc)

@router.get("")
async def get_notifications(current_user: UserInDB = Depends(get_current_user), db = Depends(get_db)):
    cursor = db.notifications.find({"userId": current_user.id}).sort("createdAt", -1).limit(50)
    docs = await cursor.to_list(length=50)
    
    unread_count = await db.notifications.count_documents({"userId": current_user.id, "read": False})
    
    return {
        "notifications": [NotificationResponse.from_mongo(n).model_dump() for n in docs],
        "unreadCount": unread_count
    }

@router.put("/{notif_id}/read")
async def mark_read(notif_id: str, current_user: UserInDB = Depends(get_current_user), db = Depends(get_db)):
    if not ObjectId.is_valid(notif_id):
        raise HTTPException(status_code=400, detail="Invalid ID")
        
    result = await db.notifications.update_one(
        {"_id": ObjectId(notif_id), "userId": current_user.id},
        {"$set": {"read": True}}
    )
    return {"success": result.modified_count > 0}

@router.put("/read-all")
async def mark_all_read(current_user: UserInDB = Depends(get_current_user), db = Depends(get_db)):
    await db.notifications.update_many(
        {"userId": current_user.id, "read": False},
        {"$set": {"read": True}}
    )
    return {"success": True}
