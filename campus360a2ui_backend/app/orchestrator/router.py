from typing import Any
import re
from app.services.openai_service import OpenAIService
from app.orchestrator.state import SessionState
from app.services.ui_generator import A2UIResponse, UIGenerator
# Import actual local handlers when built
# from app.orchestrator.handlers.task_handler import TaskHandler
# from app.orchestrator.handlers.meeting_handler import MeetingHandler

class IntentRouter:
    def __init__(self, openai_service: OpenAIService):
        self.openai_service = openai_service
    
    async def route(self, message: str, session: SessionState, value: Any = None) -> A2UIResponse:
        original_message = message.strip()
        message_lower = original_message.lower()
        session.last_message = original_message
        
        print(f"DEBUG: Routing user {session.user_id}: '{original_message}' | wf: {session.current_workflow}", flush=True)

        if message_lower in ["cancel", "stop", "nevermind"]:
            session.current_workflow = None
            session.current_step = None
            return A2UIResponse(
                session_id=session.user_id,
                message="Okay, I've cancelled the current request. How else can I help you?",
                ui=[UIGenerator.text("Request cancelled.")]
            )
        
        if message_lower.startswith("action_"):
            intent = "unknown"
            if "meeting" in message_lower: intent = "meeting"
            elif "task" in message_lower: intent = "task"
            entities = {}
        else:
            intent_res = await self.openai_service.detect_intent(original_message)
            intent = intent_res.intent
            entities = intent_res.entities
            print(f"DEBUG: Detected intent: {intent}", flush=True)

        is_creation_intent = any(w in message_lower for w in ["create", "add", "new", "make", "schedule", "assign"])
        is_view_intent = any(w in message_lower for w in ["show", "list", "get", "see", "my"]) and not is_creation_intent

        if intent == "task":
            # TODO: Route to Local Task Handler (translating to LessonPlans collection)
            return A2UIResponse(session_id=session.user_id, message=f"Task management handler is under construction. I understood you want to manage tasks.", ui=[])
            
        elif intent == "meeting" or intent == "create_meeting":
            # TODO: Route to Local Meeting Handler (translating to Events collection)
            return A2UIResponse(session_id=session.user_id, message=f"Meeting scheduling is under construction. I understood you want to manage meetings.", ui=[])

        resp_text = "I'm not sure how to help with that. I can handle tasks and meetings for Campus360."
        try:
            if 'intent_res' in locals() and intent_res.response_text:
                resp_text = intent_res.response_text
        except: pass

        return A2UIResponse(
            session_id=session.user_id,
            message=resp_text,
            ui=[]
        )
