from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List, Any
from datetime import datetime
from app.models.user import PyObjectId

class DocumentRef(BaseModel):
    name: str
    url: str
    type: str
    size: float

class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    subject: Optional[str] = None
    class_: Optional[str] = Field(alias="class", default=None)
    date: datetime
    status: str = "Pending"
    documents: List[DocumentRef] = []
    teacher: Optional[PyObjectId] = None
    schoolId: PyObjectId

class TaskInDB(TaskBase):
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

    model_config = ConfigDict(arbitrary_types_allowed=True, populate_by_name=True)

class TaskResponse(TaskBase):
    id: str
    teacher: Optional[str] = None
    schoolId: str

    @classmethod
    def from_mongo(cls, mongo_doc):
        if not mongo_doc:
            return None
        doc = dict(mongo_doc)
        if "_id" in doc: doc["id"] = str(doc.pop("_id"))
        if "teacher" in doc and doc["teacher"]: doc["teacher"] = str(doc["teacher"])
        if "schoolId" in doc and doc["schoolId"]: doc["schoolId"] = str(doc["schoolId"])
        return cls(**doc)

class EventBase(BaseModel):
    title: str
    description: Optional[str] = None
    date: datetime
    audience: str = "all"
    type: str = "meeting" # Maps to Node.js event types
    schoolId: PyObjectId
    location: Optional[str] = None
    url: Optional[str] = None

class EventInDB(EventBase):
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

    model_config = ConfigDict(arbitrary_types_allowed=True, populate_by_name=True)

class EventResponse(EventBase):
    id: str
    schoolId: str
    
    @classmethod
    def from_mongo(cls, mongo_doc):
        if not mongo_doc:
            return None
        doc = dict(mongo_doc)
        if "_id" in doc: doc["id"] = str(doc.pop("_id"))
        if "schoolId" in doc and doc["schoolId"]: doc["schoolId"] = str(doc["schoolId"])
        return cls(**doc)
