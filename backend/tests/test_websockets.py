import pytest
from unittest.mock import AsyncMock, MagicMock
from backend.app.websocket_manager import manager

@pytest.mark.asyncio
async def test_websocket_presence_broadcast():
    # Reset manager state before test
    manager.active_connections = {}
    manager.room_presence = {}

    # Mock websocket clients
    ws1 = MagicMock()
    ws1.accept = AsyncMock()
    ws1.send_text = AsyncMock()
    
    ws2 = MagicMock()
    ws2.accept = AsyncMock()
    ws2.send_text = AsyncMock()
    
    # User 1 connects to Room 1
    await manager.connect(room_id=1, user_id=101, email="user1@example.com", websocket=ws1)
    
    assert 1 in manager.active_connections
    assert len(manager.active_connections[1]) == 1
    assert len(manager.room_presence[1]) == 1
    
    # Verify User 1 received the presence broadcast list containing their details
    ws1.send_text.assert_called_once()
    
    # User 2 connects to Room 1
    await manager.connect(room_id=1, user_id=102, email="user2@example.com", websocket=ws2)
    
    assert len(manager.active_connections[1]) == 2
    assert len(manager.room_presence[1]) == 2
    
    # Verify User 1 has now received 2 broadcast calls (1st join + 2nd join)
    assert ws1.send_text.call_count == 2
    # Verify User 2 received 1 broadcast call
    assert ws2.send_text.call_count == 1
    
    # Send interaction from User 2
    await manager.broadcast_to_room(room_id=1, message={
        "type": "interaction",
        "user_id": 102,
        "email": "user2@example.com",
        "interaction": "👏"
    })
    
    # Verify both clients received the interaction message
    assert ws1.send_text.call_count == 3
    assert ws2.send_text.call_count == 2

    # Disconnect User 1
    await manager.disconnect(room_id=1, user_id=101, websocket=ws1)
    
    assert len(manager.active_connections[1]) == 1
    assert len(manager.room_presence[1]) == 1
    
    # Verify User 2 received the updated presence broadcast (User 1 leaving)
    assert ws2.send_text.call_count == 3
