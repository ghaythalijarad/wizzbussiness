"""
Main application entry point using proper OOP architecture.
"""
from .application import create_app

# Create the FastAPI application using the application factory
app = create_app()

if __name__ == "__main__":
    import uvicorn
    import os
    
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=port,
        reload=False  # Disable reload in production
    )
