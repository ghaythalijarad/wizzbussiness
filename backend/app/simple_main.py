"""
Simple FastAPI app without database dependency - for testing Heroku deployment.
"""
import os
from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI(title="Wizz API - Simple Mode", version="1.0.0")

@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "Wizz API is running in simple mode", "status": "success"}

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "message": "Application is running",
        "mode": "simple",
        "port": os.environ.get("PORT", "unknown")
    }

@app.get("/test")
async def test_endpoint():
    """Test endpoint to verify API is working."""
    return {
        "message": "Test endpoint working",
        "environment": {
            "debug": os.environ.get("DEBUG", "unknown"),
            "port": os.environ.get("PORT", "unknown"),
            "has_mongo_uri": "yes" if os.environ.get("MONGO_URI") else "no"
        }
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
