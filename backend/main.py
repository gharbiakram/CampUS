from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import auth
from app.routes import announcements

# Create FastAPI app
app = FastAPI(
    title="SmartCampus API",
    description="API for SmartCampus Companion mobile app",
    version="1.0.0",
)

# Add CORS middleware to allow requests from the Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins (change in production)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include auth routes
app.include_router(auth.router)
app.include_router(announcements.router)


@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "ok", "message": "SmartCampus API is running"}


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "app": "SmartCampus API",
        "version": "1.0.0",
        "docs": "/docs",
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
