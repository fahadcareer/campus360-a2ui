from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
from app.database.mongodb import get_db
from app.models.user import UserInDB
from app.api.auth import get_current_user
from app.models.chat import ChatMessageResponse
from bson import ObjectId

router = APIRouter()

@router.get("")
async def get_chats(
    academicYear: Optional[str] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1),
    current_user: UserInDB = Depends(get_current_user), 
    db = Depends(get_db)
):
    # Ported from Node.js chats.js
    query = {
        "participants": current_user.id,
        "schoolId": current_user.schoolId
    }
    
    if academicYear:
        query["$or"] = [
            {"isGroup": False},
            {"isGroup": True, "academicYear": academicYear}
        ]
        
    skip = (page - 1) * limit
    cursor = db.chats.find(query).sort("updatedAt", -1).skip(skip).limit(limit)
    chats = await cursor.to_list(length=limit)
    
    # We populate participants details
    for chat in chats:
        chat["id"] = str(chat.pop("_id"))
        chat["schoolId"] = str(chat["schoolId"])
        
        participant_ids = [ObjectId(pid) for pid in chat["participants"]]
        parts_cursor = db.users.find({"_id": {"$in": participant_ids}}, {"password": 0, "twoFactorCode": 0})
        parts_list = await parts_cursor.to_list(length=None)
        
        chat["participants"] = [
            {"id": str(p["_id"]), "firstName": p.get("firstName"), "lastName": p.get("lastName"), "avatar": p.get("avatar")} 
            for p in parts_list
        ]

    return {"chats": chats}

@router.get("/{chat_id}/messages")
async def get_chat_messages(
    chat_id: str,
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1),
    current_user: UserInDB = Depends(get_current_user), 
    db = Depends(get_db)
):
    if not ObjectId.is_valid(chat_id):
        raise HTTPException(status_code=400, detail="Invalid Chat ID")
        
    chat = await db.chats.find_one({"_id": ObjectId(chat_id)})
    if not chat or current_user.id not in chat.get("participants", []):
        raise HTTPException(status_code=403, detail="Access denied")
        
    skip = (page - 1) * limit
    cursor = db.chat_messages.find({"chatId": ObjectId(chat_id)}).sort("timestamp", -1).skip(skip).limit(limit)
    messages = await cursor.to_list(length=limit)
    
    return [ChatMessageResponse.from_mongo(m).model_dump() for m in messages]
