"""
Database configuration and session management for PostgreSQL.
"""
import logging
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import text
from .config import config

logger = logging.getLogger(__name__)


class Base(DeclarativeBase):
    """Base class for all database models."""
    pass


class DatabaseManager:
    """Database connection and session manager."""
    
    def __init__(self):
        self._engine = None
        self._session_factory = None
    
    async def connect(self) -> None:
        """Initialize database connection."""
        try:
            # Create async engine for PostgreSQL
            self._engine = create_async_engine(
                config.database.database_url,
                echo=config.debug,  # Log SQL queries in debug mode
                pool_size=10,
                max_overflow=20,
                pool_pre_ping=True,  # Verify connections before use
                pool_recycle=3600,   # Recycle connections every hour
            )
            
            # Create session factory
            self._session_factory = async_sessionmaker(
                self._engine,
                class_=AsyncSession,
                expire_on_commit=False
            )
            
            # Test connection
            async with self._session_factory() as session:
                await session.execute(text("SELECT 1"))
                logger.info("✅ Successfully connected to PostgreSQL database")
                
        except Exception as e:
            logger.error(f"❌ Failed to connect to database: {e}")
            raise
    
    async def disconnect(self) -> None:
        """Close database connection."""
        if self._engine:
            await self._engine.dispose()
            logger.info("Database connection closed")
    
    async def get_session(self) -> AsyncGenerator[AsyncSession, None]:
        """Get database session."""
        if not self._session_factory:
            raise RuntimeError("Database not initialized. Call connect() first.")
        
        async with self._session_factory() as session:
            try:
                yield session
            except Exception:
                await session.rollback()
                raise
            finally:
                await session.close()
    
    @property
    def engine(self):
        """Get database engine."""
        return self._engine


# Global database manager instance
db_manager = DatabaseManager()


# Dependency for getting database session
async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """Dependency for getting database session in FastAPI routes."""
    async for session in db_manager.get_session():
        yield session
