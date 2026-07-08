from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect, Query, HTTPException, status
from sqlmodel import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Dict, Any, Optional
from datetime import datetime
import jwt
import json

from backend.app.db import get_db
from backend.app.models import Room, Session, Task, User
from backend.app.auth import get_current_user, settings
from backend.app.websocket_manager import manager
from backend.app.economy import calculate_session_earnings

router = APIRouter(tags=["rooms"])

# Request/Response schemas
from pydantic import BaseModel

class RoomOut(BaseModel):
    id: int
    name: str
    category: str
    is_active: bool
    active_users: List[str]  # List of emails in the room right now

class SessionStart(BaseModel):
    room_id: int

class SessionOut(BaseModel):
    id: int
    room_id: int
    user_id: int
    started_at: datetime

class TaskCreate(BaseModel):
    session_id: int
    title: str

class TaskOut(BaseModel):
    id: int
    session_id: int
    title: str
    is_completed: bool

class SessionTerminate(BaseModel):
    session_id: int

class SessionSummaryOut(BaseModel):
    session_id: int
    duration_minutes: int
    tasks_completed: int
    leaves_earned: int
    passive_leaves: int
    active_leaves: int
    new_balance: int

@router.get("/rooms", response_model=List[RoomOut])
async def get_rooms(db: AsyncSession = Depends(get_db)):
    stmt = select(Room).where(Room.is_active == True)
    res = await db.execute(stmt)
    db_rooms = res.scalars().all()
    
    rooms_with_presence = []
    for room in db_rooms:
        # Get active user emails from the WebSocket manager
        active_emails = []
        if room.id in manager.room_presence:
            active_emails = [user_info["email"] for user_info in manager.room_presence[room.id].values()]
            
        rooms_with_presence.append(
            RoomOut(
                id=room.id,
                name=room.name,
                category=room.category,
                is_active=room.is_active,
                active_users=active_emails
            )
        )
    return rooms_with_presence

@router.post("/rooms/session/start", response_model=SessionOut)
async def start_session(data: SessionStart, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    # Create new session
    session = Session(
        user_id=current_user.id,
        room_id=data.room_id,
        started_at=datetime.utcnow()
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session

@router.post("/rooms/session/tasks", response_model=TaskOut)
async def add_task(data: TaskCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    # Check session ownership
    sess_stmt = select(Session).where(and_(Session.id == data.session_id, Session.user_id == current_user.id))
    sess_res = await db.execute(sess_stmt)
    session = sess_res.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Active session not found")
        
    task = Task(
        session_id=data.session_id,
        user_id=current_user.id,
        title=data.title,
        is_completed=False
    )
    db.add(task)
    await db.commit()
    await db.refresh(task)
    
    # Broadcast current task via WebSocket presence list
    await manager.update_presence_task(session.room_id, current_user.id, task.title)
    
    return task

@router.put("/rooms/session/tasks/{task_id}/complete", response_model=TaskOut)
async def complete_task(task_id: int, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    stmt = select(Task).where(and_(Task.id == task_id, Task.user_id == current_user.id))
    res = await db.execute(stmt)
    task = res.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    task.is_completed = True
    task.completed_at = datetime.utcnow()
    db.add(task)
    await db.commit()
    await db.refresh(task)
    
    # Broadcast completed task update
    sess_stmt = select(Session).where(Session.id == task.session_id)
    sess_res = await db.execute(sess_stmt)
    session = sess_res.scalar_one_or_none()
    if session:
        await manager.update_presence_task(session.room_id, current_user.id, f"✅ {task.title}")
        
    return task

@router.post("/rooms/session/terminate", response_model=SessionSummaryOut)
async def terminate_session(data: SessionTerminate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    stmt = select(Session).where(and_(Session.id == data.session_id, Session.user_id == current_user.id))
    res = await db.execute(stmt)
    session = res.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.ended_at:
        raise HTTPException(status_code=400, detail="Session already terminated")
        
    session.ended_at = datetime.utcnow()
    duration_delta = session.ended_at - session.started_at
    session.duration_seconds = int(duration_delta.total_seconds())
    
    # Get completed tasks count for this session
    tasks_stmt = select(Task).where(and_(Task.session_id == session.id, Task.is_completed == True))
    tasks_res = await db.execute(tasks_stmt)
    completed_tasks = len(tasks_res.scalars().all())
    
    # Economy leaves calculation
    leaves_earned, passive_leaves, active_leaves = calculate_session_earnings(
        session.duration_seconds, completed_tasks
    )
    
    session.leaves_earned = leaves_earned
    session.passive_leaves = passive_leaves
    session.active_leaves = active_leaves
    
    # Update user balance
    stmt_user = select(User).where(User.id == current_user.id)
    user_res = await db.execute(stmt_user)
    db_user = user_res.scalar_one()
    db_user.leaves_balance += leaves_earned
    
    db.add(session)
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    
    duration_minutes = max(int(duration_delta.total_seconds() // 60), 1)
    
    return SessionSummaryOut(
        session_id=session.id,
        duration_minutes=duration_minutes,
        tasks_completed=completed_tasks,
        leaves_earned=leaves_earned,
        passive_leaves=passive_leaves,
        active_leaves=active_leaves,
        new_balance=db_user.leaves_balance
    )

# WebSocket connection endpoint
@router.websocket("/rooms/{room_id}/ws")
async def websocket_endpoint(websocket: WebSocket, room_id: int, token: str = Query(...), db: AsyncSession = Depends(get_db)):
    # Validate token
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
    except Exception:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return
        
    # Get user
    stmt = select(User).where(User.email == email)
    res = await db.execute(stmt)
    user = res.scalar_one_or_none()
    if not user:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return
        
    # Connect and initialize with their current focus task if they have one
    sess_stmt = select(Session).where(
        and_(
            Session.user_id == user.id,
            Session.room_id == room_id,
            Session.ended_at == None
        )
    ).order_by(Session.id.desc())
    sess_res = await db.execute(sess_stmt)
    session = sess_res.scalars().first()
    
    current_task_title = ""
    if session:
        task_stmt = select(Task).where(
            and_(
                Task.session_id == session.id,
                Task.is_completed == False
            )
        ).order_by(Task.id.desc())
        task_res = await db.execute(task_stmt)
        latest_task = task_res.scalars().first()
        if latest_task:
            current_task_title = latest_task.title
            
    # Connect
    await manager.connect(room_id, user.id, user.email, websocket)
    if current_task_title:
        # Save task to presence list manually after connect
        manager.room_presence[room_id][user.id]["current_task"] = current_task_title
        # Broadcast initial updated presence list to room
        await manager.broadcast_presence(room_id)
    
    try:
        while True:
            # Wait for any incoming messages (pings or silent interactions)
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # If the user sends a silent interaction (👏, ☕, 🌟)
            if message.get("type") == "interaction":
                interaction_type = message.get("interaction")
                if interaction_type in ["👏", "☕", "🌟"]:
                    await manager.broadcast_to_room(room_id, {
                        "type": "interaction",
                        "user_id": user.id,
                        "email": user.email,
                        "interaction": interaction_type
                    })
            elif message.get("type") == "ping":
                # Keep-alive ping, reply with pong
                await websocket.send_text(json.dumps({"type": "pong"}))
                
    except WebSocketDisconnect:
        await manager.disconnect(room_id, user.id, websocket)
    except Exception as e:
        import traceback
        print(f"❌ WebSocket Loop Error: {e}")
        traceback.print_exc()
        await manager.disconnect(room_id, user.id, websocket)
