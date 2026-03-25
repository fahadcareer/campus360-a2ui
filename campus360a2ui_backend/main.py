from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.database.mongodb import init_db, close_db
from app.api import auth, users, tasks, events, notifications, chat, bot
from app.websockets import user_chat_socket, ai_chat_socket
import uvicorn

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("Initializing Database Connection...")
    await init_db()
    yield
    # Shutdown
    print("Closing Database Connection...")
    await close_db()

app = FastAPI(
    title="Campus360 A2UI Backend",
    description="Hybrid REST & AI WebSocket Backend for Campus360",
    version="1.0.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Update this to specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Welcome to Campus360 A2UI API"}

app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(tasks.router, prefix="/api/tasks", tags=["Tasks"])
app.include_router(events.router, prefix="/api/events", tags=["Events"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["Notifications"])
app.include_router(chat.router, prefix="/api/chats", tags=["Chats"])
app.include_router(bot.router, prefix="/api/bot", tags=["Bot AI Chat"])

app.include_router(user_chat_socket.router, tags=["WebSockets Human Chat"])
app.include_router(ai_chat_socket.router, tags=["WebSockets AI Chat"])

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=5000, reload=True)
