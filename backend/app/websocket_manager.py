from fastapi import WebSocket
from typing import Dict, List, Set, Any
import json

class WebSocketManager:
    def __init__(self):
        # Room ID -> List of active WebSocket connections
        self.active_connections: Dict[int, List[WebSocket]] = {}
        # Room ID -> Dict of user_id -> User presence info (email, etc.)
        self.room_presence: Dict[int, Dict[int, Dict[str, Any]]] = {}

    async def connect(self, room_id: int, user_id: int, email: str, websocket: WebSocket):
        await websocket.accept()
        
        if room_id not in self.active_connections:
            self.active_connections[room_id] = []
        if room_id not in self.room_presence:
            self.room_presence[room_id] = {}
            
        self.active_connections[room_id].append(websocket)
        self.room_presence[room_id][user_id] = {
            "user_id": user_id,
            "email": email,
            "joined_at": str(websocket.created_at if hasattr(websocket, 'created_at') else ""),
            "current_task": ""
        }
        
        # Broadcast the updated presence list to everyone in the room
        await self.broadcast_presence(room_id)

    async def disconnect(self, room_id: int, user_id: int, websocket: WebSocket):
        if room_id in self.active_connections:
            if websocket in self.active_connections[room_id]:
                self.active_connections[room_id].remove(websocket)
            if not self.active_connections[room_id]:
                del self.active_connections[room_id]
                
        if room_id in self.room_presence:
            if user_id in self.room_presence[room_id]:
                del self.room_presence[room_id][user_id]
            if not self.room_presence[room_id]:
                del self.room_presence[room_id]
                
        # Broadcast updated presence
        await self.broadcast_presence(room_id)

    async def broadcast_to_room(self, room_id: int, message: Dict[str, Any]):
        if room_id in self.active_connections:
            payload = json.dumps(message)
            for connection in self.active_connections[room_id]:
                try:
                    await connection.send_text(payload)
                except Exception:
                    # Connection might be dead, handle cleanup separately or ignore
                    pass

    async def broadcast_presence(self, room_id: int):
        presence_users = list(self.room_presence.get(room_id, {}).values())
        await self.broadcast_to_room(room_id, {
            "type": "presence",
            "users": presence_users
        })

    async def update_presence_task(self, room_id: int, user_id: int, task_title: str):
        if room_id in self.room_presence and user_id in self.room_presence[room_id]:
            self.room_presence[room_id][user_id]["current_task"] = task_title
            await self.broadcast_presence(room_id)

manager = WebSocketManager()
