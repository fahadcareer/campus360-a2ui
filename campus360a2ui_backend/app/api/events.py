from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
from datetime import datetime
from app.database.mongodb import get_db
from app.models.user import UserInDB
from app.api.auth import get_current_user
from app.models.content import EventResponse
from bson import ObjectId

router = APIRouter()

@router.get("", response_model=dict)
async def get_events(
    dateFrom: Optional[datetime] = None,
    dateTo: Optional[datetime] = None,
    audience: Optional[str] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(200, ge=1),
    current_user: UserInDB = Depends(get_current_user), 
    db = Depends(get_db)
):
    query = {"schoolId": current_user.schoolId}
    
    # Role-based visibility logic ported from Node.js events.js
    if current_user.role == 'student':
        query["audience"] = {"$in": ["all", "students"]}
    elif current_user.role == 'parent':
        query["audience"] = {"$in": ["all", "parents"]}
    elif current_user.role == 'teacher':
        query["audience"] = {"$in": ["all", "teachers"]}
    elif audience and audience != 'all':
        query["audience"] = audience
        
    date_query = {}
    if dateFrom: date_query["$gte"] = dateFrom
    if dateTo: date_query["$lte"] = dateTo
    if date_query: query["date"] = date_query
        
    skip = (page - 1) * limit
    cursor = db.events.find(query).sort("date", 1).skip(skip).limit(limit)
    events = await cursor.to_list(length=limit)
    total = await db.events.count_documents(query)
    
    return {
        "events": [EventResponse.from_mongo(e).model_dump() for e in events],
        "total": total,
        "page": page,
        "pages": (total + limit - 1) // limit
    }
