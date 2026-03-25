from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
from datetime import datetime
from app.database.mongodb import get_db
from app.models.user import UserInDB
from app.api.auth import get_current_user
from app.models.content import TaskResponse
from bson import ObjectId

router = APIRouter()

@router.get("", response_model=dict)
async def get_tasks(
    status: Optional[str] = None,
    startDate: Optional[datetime] = None,
    endDate: Optional[datetime] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    current_user: UserInDB = Depends(get_current_user), 
    db = Depends(get_db)
):
    query = {"schoolId": current_user.schoolId}
    
    # Teachers only see their own plans initially
    if current_user.role == 'teacher':
        query["teacher"] = current_user.id
        
    if status:
        query["status"] = status
        
    if startDate and endDate:
        query["date"] = {
            "$gte": startDate,
            "$lte": endDate
        }
        
    skip = (page - 1) * limit
    cursor = db.lesson_plans.find(query).sort("createdAt", -1).skip(skip).limit(limit)
    tasks = await cursor.to_list(length=limit)
    total = await db.lesson_plans.count_documents(query)
    
    return {
        "tasks": [TaskResponse.from_mongo(t).model_dump() for t in tasks],
        "total": total,
        "page": page,
        "pages": (total + limit - 1) // limit
    }

@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(task_id: str, current_user: UserInDB = Depends(get_current_user), db = Depends(get_db)):
    if not ObjectId.is_valid(task_id):
        raise HTTPException(status_code=400, detail="Invalid Task ID")
        
    task_doc = await db.lesson_plans.find_one({"_id": ObjectId(task_id), "schoolId": current_user.schoolId})
    if not task_doc:
        raise HTTPException(status_code=404, detail="Task not found")
        
    if current_user.role == 'teacher' and str(task_doc.get("teacher")) != str(current_user.id):
        raise HTTPException(status_code=403, detail="Access denied")
        
    return TaskResponse.from_mongo(task_doc)
