import asyncio
import httpx
import websockets
import json

BASE_URL = "http://localhost:8000"
WS_URL = "ws://localhost:8000"

async def test_ws_connection():
    print("🔌 Starting WebSocket handshake diagnostics...")
    
    # 1. Register & Login to get token
    email = "diagnostic_user@example.com"
    password = "password123"
    
    async with httpx.AsyncClient() as client:
        # Register (ignore if already exists)
        await client.post(f"{BASE_URL}/auth/register", json={"email": email, "password": password})
        
        # Login
        login_res = await client.post(f"{BASE_URL}/auth/login", json={"email": email, "password": password})
        if login_res.status_code != 200:
            print(f"❌ Login failed: {login_res.text}")
            return
        
        token = login_res.json()["access_token"]
        print(f"✅ Authenticated. Token acquired: {token[:15]}...")

        # Start room session (required by backend rooms logic)
        session_res = await client.post(
            f"{BASE_URL}/rooms/session/start",
            headers={"Authorization": f"Bearer {token}"},
            json={"room_id": 1}
        )
        print(f"✅ Session start response status: {session_res.status_code}")

    # 2. Connect to WebSocket
    ws_uri = f"{WS_URL}/rooms/1/ws?token={token}"
    print(f"🔗 Attempting to connect to: {ws_uri}")
    
    try:
        async with websockets.connect(ws_uri) as ws:
            print("🚀 WebSocket Connection ACCEPTED by backend!")
            
            # Read first message (presence list broadcast)
            print("📥 Waiting for first presence broadcast...")
            message = await ws.recv()
            print(f"📥 Received raw message: {message}")
            
            # Send interaction
            print("📤 Sending silent interaction '👏'...")
            await ws.send(json.dumps({
                "type": "interaction",
                "interaction": "👏"
            }))
            
            # Read response
            response = await ws.recv()
            print(f"📥 Received interaction broadcast: {response}")
            
            print("✅ WebSocket Diagnostics Completed Successfully!")
            
    except Exception as e:
        print(f"❌ WebSocket Connection FAILED: {type(e).__name__}: {e}")

if __name__ == "__main__":
    asyncio.run(test_ws_connection())
