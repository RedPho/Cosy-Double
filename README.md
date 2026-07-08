# Cozy Double 🍃

A neurodivergent-friendly "body doubling" and focus application designed to reduce executive dysfunction through low-friction social presence and a reward-based economy. Unlike traditional productivity tools, Cozy Double prioritizes effort and presence over raw output, utilizing a "warm and focused" aesthetic to minimize mental load.

---

## 🎨 Design Philosophy
1. **Frictionless Transitions**: Instant entry and exit from focus sessions without "Are you sure?" confirmation modals.
2. **Effort-Based Rewards**: Rewarding "showing up" (passive presence) as much as "checking off" (active tasks).
3. **Warm Aesthetic**: Utilizing the "Warm & Focused" design system (Oatmeal backgrounds `#F5EFE6`, soft terracotta accents `#D95D39`, and rounded geometry).
4. **Shame-Free UX**: Welcoming users back after hiatuses without highlighting absences or broken streaks.

---

## 🏗️ Architecture & Stack

### Backend: FastAPI & PostgreSQL
- **Language**: Python 3.12+ (managed via `uv`)
- **ORM**: SQLModel / SQLAlchemy
- **Migrations**: Alembic
- **Database**: PostgreSQL (containerized via Docker Compose)
- **WebSockets**: Standard FastAPI websockets for concurrent user presence tracking and silent zone broadcasts.
- **Monetization**: Native Stripe checkout backend via PaymentIntents.

### Frontend: Flutter (Clean Architecture)
- **State Management**: `flutter_bloc` (BLoC pattern)
- **Routing**: `go_router`
- **DI**: `get_it`
- **Animations**: `flutter_animate` (leaf rewards, presence pulses)
- **Structure**:
  - `lib/core/`: Theme, network API clients, and service locator dependencies.
  - `lib/domain/`: Pure business entities and abstract repository definitions.
  - `lib/data/`: Data models (JSON parsing), datasources, and repository implementations.
  - `lib/presentation/`: BLoCs and screens (Lobby, Focus, Summary, Oasis canvas).

---

## 🚀 Getting Started

### Prerequisites
- Docker & Docker Compose
- Python 3.12+
- Flutter SDK (or Flutter IDE extensions)

### 1. Running the Backend & Database

1. Spin up the PostgreSQL database container:
   ```bash
   docker-compose up -d
   ```

2. Activate the virtual environment and install backend dependencies:
   ```bash
   source backend/.venv/bin/activate
   # (Dependencies are already installed, but to double-check:)
   pip install -r backend/requirements.txt
   ```

3. Run migrations and start the server:
   ```bash
   # Uvicorn runs on port 8000 by default
   uvicorn backend.app.main:app --port 8000 --reload
   ```

*On startup, the server automatically seeds default rooms (Deep Work Oasis, Cozy Library) and shop items (Monstera Plant, Tea Cup, Rainy Window Background) if the database is empty.*

### 2. Running the Frontend
1. Open the `/frontend` directory in your Flutter IDE (VS Code or Android Studio with Flutter extensions).
2. Fetch package dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run -d chrome # or your choice of device
   ```

---

## 🧪 Testing

We have built automated unit tests targeting the economy reward logic and websocket manager.

Run backend tests:
```bash
PYTHONPATH=. backend/.venv/bin/pytest backend/tests/
```

*Expected output:*
```text
============================== 4 passed in 0.79s ===============================
```

---

## 🍃 Economy Formula
- **Passive Income (Presence)**: 1 Leaf per 5 minutes of connection.
- **Active Income (Execution)**: 2 Leaves per task marked [DONE].
- **Anti-Farming Cap**: Passive earnings are capped at 30 Leaves per session (~2.5 hours) to prevent idle farming.
