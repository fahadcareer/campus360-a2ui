from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List, Any
from datetime import datetime
from app.models.user import PyObjectId

class ChatBase(BaseModel):
    isGroup: bool = False
    roomName: Optional[str] = None
    academicYear: Optional[str] = None
    participants: List[PyObjectId]
    schoolId: PyObjectId
    lastMessage: Optional[str] = None

class ChatInDB(ChatBase):
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

    model_config = ConfigDict(arbitrary_types_allowed=True, populate_by_name=True)

class ChatMessageBase(BaseModel):
    chatId: PyObjectId
    sender: PyObjectId
    content: str
    type: str = "text"
    readBy: List[PyObjectId] = []

class ChatMessageInDB(ChatMessageBase):
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    timestamp: Optional[datetime] = None
    
    model_config = ConfigDict(arbitrary_types_allowed=True, populate_by_name=True)

class ChatMessageResponse(ChatMessageBase):
    id: str
    chatId: str
    sender: str
    readBy: List[str] = []

    @classmethod
    def from_mongo(cls, mongo_doc):
        if not mongo_doc: return None
        doc = dict(mongo_doc)
        if "_id" in doc: doc["id"] = str(doc.pop("_id"))
        if "chatId" in doc: doc["chatId"] = str(doc["chatId"])
        if "sender" in doc: doc["sender"] = str(doc["sender"])
        doc["readBy"] = [str(uid) for uid in doc.get("readBy", [])]
        return cls(**doc)
