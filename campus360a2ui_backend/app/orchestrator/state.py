import json
from typing import Dict, Any, Optional, List
from pydantic import BaseModel
import os

class Notification(BaseModel):
    id: str
    title: str
    message: str
    trigger_at: str # ISO format
    data: Optional[Dict[str, Any]] = None
    status: str = "pending" # 'pending', 'sent', 'failed'

class SessionState(BaseModel):
    user_id: str
    current_workflow: Optional[str] = None # 'task', 'meeting'
    current_step: Optional[str] = None
    collected_data: Dict[str, Any] = {}
    last_message: Optional[str] = None
    auth_token: Optional[str] = None
    role: Optional[str] = None
    timezone_offset: Optional[int] = None # in minutes (Local - UTC)

    def set_field(self, field: str, value: Any):
        self.collected_data[field] = value

class StateStore:
    def __init__(self, persist_path: str = "state_store.json"):
        # Put it in a temp dir if running locally, ideally should use Redis for prod.
        self.persist_path = persist_path
        self._sessions: Dict[str, SessionState] = {}
        self._load()

    def _save(self):
        try:
            with open(self.persist_path, "w") as f:
                data = {uid: sess.model_dump() for uid, sess in self._sessions.items()}
                json.dump(data, f)
        except Exception as e:
            print(f"DEBUG: Error saving StateStore: {e}")

    def _load(self):
        if os.path.exists(self.persist_path):
            try:
                with open(self.persist_path, "r") as f:
                    data = json.load(f)
                    self._sessions = {uid: SessionState(**sess) for uid, sess in data.items()}
                print(f"DEBUG: Loaded {len(self._sessions)} sessions from {self.persist_path}")
            except Exception as e:
                print(f"DEBUG: Error loading StateStore: {e}")

    def get_session(self, user_id: str) -> SessionState:
        user_id_str = str(user_id)
        if user_id_str not in self._sessions:
            self._sessions[user_id_str] = SessionState(user_id=user_id_str)
            self._save()
        return self._sessions[user_id_str]

    def update_session(self, user_id: str, **kwargs):
        session = self.get_session(user_id)
        for key, value in kwargs.items():
            if hasattr(session, key):
                setattr(session, key, value)
        self._save()
        return session

    def set_session_field(self, user_id: str, field: str, value: Any):
        session = self.get_session(user_id)
        session.set_field(field, value)
        self._save()

    def clear_session(self, user_id: str):
        user_id_str = str(user_id)
        if user_id_str in self._sessions:
            self._sessions[user_id_str] = SessionState(user_id=user_id_str)
            self._save()
