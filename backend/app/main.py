"""
Main application entry point using proper OOP architecture.
"""
from .application import create_app

# Create the FastAPI application using the application factory
app = create_app()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
