from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Optional, Dict, List
from app.database.mongodb import get_db
from app.models.user import UserInDB, UserResponse
from bson import ObjectId
from app.api.auth import get_current_user

router = APIRouter()

class UserUpdate(BaseModel):
    firstName: Optional[str] = None
    lastName: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    avatar: Optional[str] = None
    signature: Optional[str] = None

@router.get("/directory")
async def get_directory(current_user: UserInDB = Depends(get_current_user), db = Depends(get_db)):
    """
    Get user directory grouped by roles, respecting school isolation and basic visibility rules.
    """
    if not current_user.schoolId:
        return {}

    query = {
        "schoolId": current_user.schoolId,
        "$or": [{"isActive": True}, {"isActive": {"$exists": False}}]
    }
    
    requester_role = current_user.role.lower()
    
    # Ported from Node.js directory logic
    if requester_role == 'student':
        query["role"] = {"$in": ["teacher", "admin"]}
    elif requester_role == 'parent':
        query["role"] = {"$in": ["teacher", "admin"]}
    elif requester_role == 'teacher':
        query["role"] = {"$in": ["student", "parent", "teacher", "admin"]}
        
    cursor = db.users.find(query, {"password": 0, "twoFactorCode": 0, "twoFactorExpires": 0, "passwordResetCode": 0, "passwordResetExpires": 0})
    users = await cursor.to_list(length=1000)
    
    grouped = {}
    for user_doc in users:
        user = UserResponse.from_mongo(user_doc)
        role_label = user.role.capitalize() if user.role else "Other"
        if role_label not in grouped:
            grouped[role_label] = []
        grouped[role_label].append(user.model_dump())
        
    return grouped

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: str, current_user: UserInDB = Depends(get_current_user), db = Depends(get_db)):
    if not ObjectId.is_valid(user_id):
        raise HTTPException(status_code=400, detail="Invalid User ID")
        
    user_doc = await db.users.find_one({"_id": ObjectId(user_id)})
    if not user_doc:
        raise HTTPException(status_code=404, detail="User not found")
        
    return UserResponse.from_mongo(user_doc)

@router.put("/{user_id}", response_model=UserResponse)
async def update_user(user_id: str, update_data: UserUpdate, current_user: UserInDB = Depends(get_current_user), db = Depends(get_db)):
    if not ObjectId.is_valid(user_id):
        raise HTTPException(status_code=400, detail="Invalid User ID")
        
    if current_user.role != "admin" and str(current_user.id) != user_id:
        raise HTTPException(status_code=403, detail="Access denied. You can only edit your own profile.")
        
    update_dict = {k: v for k, v in update_data.model_dump().items() if v is not None}
    if not update_dict:
        return UserResponse.from_mongo(await db.users.find_one({"_id": ObjectId(user_id)}))
        
    await db.users.update_one(
        {"_id": ObjectId(user_id)},
        {"$set": update_dict}
    )
    
    updated_doc = await db.users.find_one({"_id": ObjectId(user_id)})
    return UserResponse.from_mongo(updated_doc)
