from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Optional, List, Any
from datetime import datetime
from bson import ObjectId

class PyObjectId(ObjectId):
    @classmethod
    def __get_pydantic_core_schema__(cls, _source_type: Any, _handler: Any):
        from pydantic_core import core_schema
        return core_schema.union_schema([
            core_schema.is_instance_schema(ObjectId),
            core_schema.no_info_plain_validator_function(cls.validate)
        ])

    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid ObjectId")
        return ObjectId(v)

class UserBase(BaseModel):
    firstName: str
    lastName: str
    email: EmailStr
    role: str
    phone: Optional[str] = None
    address: Optional[str] = None
    avatar: Optional[str] = None
    signature: Optional[str] = None
    schoolId: Optional[PyObjectId] = None
    isActive: Optional[bool] = True

class UserInDB(UserBase):
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    password: str
    twoFactorCode: Optional[str] = None
    twoFactorExpires: Optional[datetime] = None
    passwordResetCode: Optional[str] = None
    passwordResetExpires: Optional[datetime] = None
    lastLogin: Optional[datetime] = None
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None
    
    model_config = ConfigDict(arbitrary_types_allowed=True, populate_by_name=True)

class UserResponse(UserBase):
    id: str

    @classmethod
    def from_mongo(cls, mongo_doc):
        if not mongo_doc:
            return None
        doc = dict(mongo_doc)
        if "_id" in doc:
            doc["id"] = str(doc.pop("_id"))
        if "schoolId" in doc and doc["schoolId"]:
             doc["schoolId"] = str(doc["schoolId"])
        return cls(**doc)

class SchoolBase(BaseModel):
    name: str
    email: EmailStr
    phone: Optional[str] = None
    address: Optional[str] = None
    isActive: bool = True
    subscriptionEnd: Optional[datetime] = None

class SchoolInDB(SchoolBase):
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

    model_config = ConfigDict(arbitrary_types_allowed=True, populate_by_name=True)
