from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from app.database.mongodb import get_db
from app.models.user import UserInDB, UserResponse
from app.models.user import SchoolInDB
from app.services.auth_service import verify_password, create_access_token, decode_access_token
from fastapi.security import OAuth2PasswordBearer
from datetime import datetime

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")

class LoginRequest(BaseModel):
    email: str
    password: str

async def get_current_user(token: str = Depends(oauth2_scheme), db = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_access_token(token)
        user_id: str = payload.get("userId")
        if user_id is None:
            raise credentials_exception
    except Exception:
        raise credentials_exception
        
    from bson import ObjectId
    user = await db.users.find_one({"_id": ObjectId(user_id)})
    if user is None:
        raise credentials_exception
    return UserInDB(**user)

@router.post("/login")
async def login(request: LoginRequest, db = Depends(get_db)):
    user_doc = await db.users.find_one({"email": request.email})
    if not user_doc:
        raise HTTPException(status_code=400, detail="Invalid credentials")
        
    user = UserInDB(**user_doc)
    
    # Check School Status
    if user.schoolId:
        school_doc = await db.schools.find_one({"_id": user.schoolId})
        if school_doc:
            school = SchoolInDB(**school_doc)
            if not school.isActive:
                raise HTTPException(status_code=403, detail="Your school account is currently deactivated. Please contact support.")
            if school.subscriptionEnd and datetime.utcnow() > school.subscriptionEnd:
                raise HTTPException(status_code=403, detail="Your school subscription has expired. Please contact administration.")
                
    if not verify_password(request.password, user.password):
        raise HTTPException(status_code=400, detail="Invalid credentials")
        
    # Standard Node.js payload was { userId, role }
    access_token = create_access_token(data={"userId": str(user.id), "role": user.role})
    
    # Update last login
    await db.users.update_one({"_id": user.id}, {"$set": {"lastLogin": datetime.utcnow()}})
    
    return {
        "token": access_token,
        "user": UserResponse.from_mongo(user_doc)
    }

@router.get("/me", response_model=UserResponse)
async def get_me(current_user: UserInDB = Depends(get_current_user)):
    user_dict = current_user.model_dump(by_alias=True)
    return UserResponse.from_mongo(user_dict)
