from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from typing import Optional
import json
from datetime import datetime
from bson import ObjectId
from app.websockets.connection_manager import manager
from app.services.auth_service import decode_access_token
from app.database.mongodb import get_db

router = APIRouter()

@router.websocket("/ws/chat")
async def user_chat_websocket(
    websocket: WebSocket,
    token: Optional[str] = Query(None)
):
    # Authenticate via token in query
    if not token:
        await websocket.close(code=1008)
        return
        
    try:
        payload = decode_access_token(token)
        user_id = payload.get("userId")
        if not user_id:
            await websocket.close(code=1008)
            return
    except Exception as e:
        await websocket.close(code=1008)
        return

    await manager.connect(websocket, user_id)
    db = get_db()
    
    try:
        while True:
            data = await websocket.receive_text()
            try:
                payload = json.loads(data)
                action = payload.get("action")
                
                if action == "send_message":
                    chat_id = payload.get("chat_id")
                    content = payload.get("content")
                    msg_type = payload.get("type", "text")
                    
                    if not chat_id or not content:
                        continue
                        
                    # 1. Verify Chat exists and user is participant
                    chat = await db.chats.find_one({"_id": ObjectId(chat_id)})
                    if not chat or ObjectId(user_id) not in chat.get("participants", []):
                        continue
                        
                    # 2. Save Message to DB
                    new_msg = {
                        "chatId": ObjectId(chat_id),
                        "sender": ObjectId(user_id),
                        "content": content,
                        "type": msg_type,
                        "readBy": [ObjectId(user_id)],
                        "timestamp": datetime.utcnow()
                    }
                    result = await db.chat_messages.insert_one(new_msg)
                    msg_id = str(result.inserted_id)
                    
                    # 3. Update Chat Last Message
                    await db.chats.update_one(
                        {"_id": ObjectId(chat_id)},
                        {"$set": {"lastMessage": content, "updatedAt": datetime.utcnow()}}
                    )

                    # 4. Broadcast to other online participants
                    broadcast_data = {
                        "event": "new_message",
                        "message": {
                            "id": msg_id,
                            "chatId": chat_id,
                            "sender": user_id,
                            "content": content,
                            "type": msg_type,
                            "timestamp": new_msg["timestamp"].isoformat()
                        }
                    }
                    
                    other_participants = [str(pid) for pid in chat["participants"] if str(pid) != user_id]
                    for pid in other_participants:
                        # Emits only if online; offline users will see it via REST history later
                        await manager.broadcast_to_user(pid, broadcast_data)

            except json.JSONDecodeError:
                pass
                
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
