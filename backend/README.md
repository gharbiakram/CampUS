# SmartCampus Companion — FastAPI Backend

A simple FastAPI backend for the SmartCampus Companion mobile app providing authentication and user management.

## Quick Start

### Prerequisites
- Python 3.10+
- pip

### Installation

```bash
cd backend
pip install -r requirements.txt
```

### Run the Server

```bash
uvicorn main:app --reload --port 8000
```

The API will be available at `http://localhost:8000`
- Interactive API docs: `http://localhost:8000/docs`
- Alternative API docs: `http://localhost:8000/redoc`

## Demo Credentials

For testing, use these credentials:
- **Email:** `test@campus.com`
- **Password:** `password`

## API Endpoints

### Authentication

#### Login
```
POST /api/auth/login
Content-Type: application/json

{
  "email": "test@campus.com",
  "password": "password"
}
```

Response (Success):
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "email": "test@campus.com",
  "name": "Test Student"
}
```

#### Logout
```
POST /api/auth/logout
```

### Health Check
```
GET /api/health
```

## Project Structure

```
backend/
├── app/
│   ├── models/       # Pydantic models for request/response
│   ├── routes/       # API route handlers
│   ├── utils/        # Utility functions (security, etc.)
│   └── __init__.py
├── main.py           # FastAPI app entry point
├── requirements.txt  # Python dependencies
└── README.md         # This file
```

## Next Steps

- [ ] Add database integration (SQLite/PostgreSQL)
- [ ] Implement user registration
- [ ] Add announcements and events endpoints
- [ ] Add campus map/POI endpoints
- [ ] Implement notification scheduling
- [ ] Add role-based access control (Student/Staff)
