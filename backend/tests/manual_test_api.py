import httpx
import time

BASE_URL = "http://localhost:8000"

def test_full_api_flow():
    print("🚀 Starting Cozy Double E2E REST API Manual Test...")

    # Unique test email to avoid duplicate errors
    test_email = f"user_{int(time.time())}@example.com"
    test_password = "password123"

    with httpx.Client(base_url=BASE_URL) as client:
        # 1. Register a new user
        print(f"\n1. Registering user: {test_email}")
        reg_response = client.post("/auth/register", json={
            "email": test_email,
            "password": test_password
        })
        print(f"Status: {reg_response.status_code}")
        assert reg_response.status_code == 201
        user_data = reg_response.json()
        print(f"Registered User Info: {user_data}")
        # Default welcome leaves
        assert user_data["leaves_balance"] == 10

        # 2. Login
        print("\n2. Logging in...")
        login_response = client.post("/auth/login", json={
            "email": test_email,
            "password": test_password
        })
        print(f"Status: {login_response.status_code}")
        assert login_response.status_code == 200
        token_data = login_response.json()
        token = token_data["access_token"]
        print(f"Received access token: {token[:25]}...")

        headers = {"Authorization": f"Bearer {token}"}

        # 3. Get Active Rooms
        print("\n3. Fetching active focus rooms...")
        rooms_response = client.get("/rooms", headers=headers)
        print(f"Status: {rooms_response.status_code}")
        assert rooms_response.status_code == 200
        rooms = rooms_response.json()
        print(f"Available Focus Rooms: {rooms}")
        assert len(rooms) > 0
        target_room_id = rooms[0]["id"]

        # 4. Start Focus Session
        print(f"\n4. Entering Room {target_room_id} and starting focus session...")
        session_response = client.post("/rooms/session/start", headers=headers, json={
            "room_id": target_room_id
        })
        print(f"Status: {session_response.status_code}")
        assert session_response.status_code == 200
        session_data = session_response.json()
        session_id = session_data["id"]
        print(f"Started Session ID: {session_id}")

        # 5. Add a "Tiny Step" Task
        print("\n5. Adding a tiny step task...")
        task_response = client.post("/rooms/session/tasks", headers=headers, json={
            "session_id": session_id,
            "title": "Clean keyboard"
        })
        print(f"Status: {task_response.status_code}")
        assert task_response.status_code == 200
        task_data = task_response.json()
        task_id = task_data["id"]
        print(f"Created Task Info: {task_data}")

        # 6. Complete the Task (claims active leaves)
        print(f"\n6. Checking off Task {task_id}...")
        complete_response = client.put(f"/rooms/session/tasks/{task_id}/complete", headers=headers)
        print(f"Status: {complete_response.status_code}")
        assert complete_response.status_code == 200
        completed_task_data = complete_response.json()
        print(f"Completed Task Info: {completed_task_data}")
        assert completed_task_data["is_completed"] is True

        # Simulate focusing (Wait 3 seconds)
        print("\n⏱️ Simulating focus connection (waiting 3s)...")
        time.sleep(3)

        # 7. Pack Up & Leave (Terminate Session)
        print("\n7. Terminating session (claiming earnings)...")
        terminate_response = client.post("/rooms/session/terminate", headers=headers, json={
            "session_id": session_id
        })
        print(f"Status: {terminate_response.status_code}")
        assert terminate_response.status_code == 200
        summary_data = terminate_response.json()
        print(f"Focus Summary Report: {summary_data}")
        
        # Checked task = 2 active leaves
        assert summary_data["active_leaves"] == 2
        # Verify wallet credited
        assert summary_data["new_balance"] == 12
        print(f"\n🎉 Success! New Leaf balance is: {summary_data['new_balance']} 🍃")

if __name__ == "__main__":
    test_full_api_flow()
