from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
from app.database.mongodb import get_db
from app.models.user import UserInDB
from app.api.auth import get_current_user
from bson import ObjectId

router = APIRouter()

@router.get("/history")
async def get_ai_history(
    current_user: UserInDB = Depends(get_current_user), 
    db = Depends(get_db)
):
    """Get the user's conversation thread with the AI bot"""
    ai_conv = await db.ai_conversations.find_one({"userId": current_user.id})
    if not ai_conv:
        return {"messages": []}
        
    conv_id = ai_conv["_id"]
    cursor = db.ai_messages.find({"conversationId": conv_id}).sort("timestamp", 1).limit(100)
    messages = await cursor.to_list(length=100)
    
    # Format for frontend
    formatted_messages = []
    for msg in messages:
        msg["id"] = str(msg.pop("_id"))
        msg["conversationId"] = str(msg["conversationId"])
        msg["timestamp"] = msg["timestamp"].isoformat() if hasattr(msg["timestamp"], 'isoformat') else msg["timestamp"]
        formatted_messages.append(msg)
        
    return {"messages": formatted_messages}
