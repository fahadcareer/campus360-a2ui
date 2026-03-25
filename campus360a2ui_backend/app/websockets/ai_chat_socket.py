from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from typing import Optional
import json
from datetime import datetime
from bson import ObjectId
from app.websockets.connection_manager import manager
from app.services.auth_service import decode_access_token
from app.database.mongodb import get_db
from app.orchestrator.router import IntentRouter
from app.services.openai_service import OpenAIService
from app.orchestrator.state import StateStore

router = APIRouter()

# Instantiate singletons for the Bot session
openai_service = OpenAIService()
intent_router = IntentRouter(openai_service)
state_store = StateStore()

@router.websocket("/ws/bot")
async def ai_chat_websocket(
    websocket: WebSocket,
    token: Optional[str] = Query(None)
):
    if not token:
        await websocket.close(code=1008)
        return
        
    try:
        payload = decode_access_token(token)
        user_id = payload.get("userId")
        role = payload.get("role")
        if not user_id:
            await websocket.close(code=1008)
            return
    except Exception as e:
        await websocket.close(code=1008)
        return

    # Use a modified user_id to separate bot connections from human-chat connections
    bot_connection_id = f"bot_{user_id}"
    await manager.connect(websocket, bot_connection_id)
    
    # Initialize user's AI session state
    session = state_store.get_session(user_id)
    session.auth_token = token
    session.role = role
    state_store._save()
    
    db = get_db()
    
    try:
        # Check for history or create first AI Conversation Thread
        ai_conv = await db.ai_conversations.find_one({"userId": ObjectId(user_id)})
        if not ai_conv:
            res = await db.ai_conversations.insert_one({"userId": ObjectId(user_id), "createdAt": datetime.utcnow()})
            conv_id = res.inserted_id
        else:
            conv_id = ai_conv["_id"]

        while True:
            data = await websocket.receive_text()
            
            try:
                # 1. Parse incoming message (Flutter sends JSON {text: "..."})
                payload = json.loads(data)
                user_text = payload.get("text")
                value = payload.get("value") # Used if it's a form submission
                
                if user_text:
                    # Save user message to MongoDB AI history
                    await db.ai_messages.insert_one({
                        "conversationId": conv_id,
                        "sender": "user",
                        "text": user_text,
                        "timestamp": datetime.utcnow()
                    })
                    
                    # 2. Route the intent using the OpenAI brain
                    response = await intent_router.route(user_text, session, value)
                    
                    # 3. Save AI response to History
                    await db.ai_messages.insert_one({
                        "conversationId": conv_id,
                        "sender": "ai",
                        "text": response.message,
                        "ui": [ui.model_dump() for ui in response.ui],
                        "timestamp": datetime.utcnow()
                    })

                    # 4. Stream response back to Flutter UI over WebSocket
                    await websocket.send_text(json.dumps({
                        "message": response.message,
                        "ui": [ui.model_dump() for ui in response.ui],
                        "timestamp": datetime.utcnow().isoformat()
                    }))
                    
            except json.JSONDecodeError:
                print("Received non-JSON text on AI socket. Ignoring.")
                
    except WebSocketDisconnect:
        manager.disconnect(websocket, bot_connection_id)
