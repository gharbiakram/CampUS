from fastapi import APIRouter, HTTPException, status
from ..models.auth import LoginRequest, LoginResponse, LogoutRequest
from ..utils.security import create_access_token

router = APIRouter(
    prefix="/api/auth",
    tags=["auth"],
)

# Hardcoded demo credentials (use a real database in production)
DEMO_USER = {
    "email": "test@campus.com",
    "password": "password",
    "name": "Test Student",
}


@router.post("/login", response_model=LoginResponse)
async def login(request: LoginRequest):
    """
    Login endpoint with email and password.
    Returns a JWT token on successful authentication.
    """
    # Demo credentials check (replace with database query in production)
    if request.email == DEMO_USER["email"] and request.password == DEMO_USER["password"]:
        # Create JWT token
        access_token = create_access_token(
            data={"sub": request.email, "email": request.email}
        )
        return LoginResponse(
            access_token=access_token,
            email=request.email,
            name=DEMO_USER["name"],
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )


@router.post("/logout")
async def logout(request: LogoutRequest):
    """
    Logout endpoint. In a real app, this would invalidate the token.
    For now, it's a simple acknowledgment.
    """
    return {"message": "Logout successful"}
