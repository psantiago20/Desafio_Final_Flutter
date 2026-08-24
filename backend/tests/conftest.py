import pytest

# Monkeypatch httpx.Client to bypass Starlette TestClient compatibility issue with httpx >= 0.28.0
import httpx
_original_init = httpx.Client.__init__
def _patched_init(self, *args, **kwargs):
    kwargs.pop("app", None)
    _original_init(self, *args, **kwargs)
httpx.Client.__init__ = _patched_init

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.db.database import Base, get_db
from app.main import app

# Database URL for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///./omniconnect_test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="function")
def db():
    # Create the database tables
    Base.metadata.create_all(bind=engine)
    db_session = TestingSessionLocal()
    try:
        yield db_session
    finally:
        db_session.close()
        # Drop the database tables to ensure clean state
        Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="function")
def client(db):
    def override_get_db():
        try:
            yield db
        finally:
            pass
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
