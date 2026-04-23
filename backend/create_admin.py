import hashlib
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

DATABASE_URL = 'postgresql://postgres:P2706303-2p@localhost:5432/omniconnect'
engine = create_engine(DATABASE_URL)
Session = sessionmaker(bind=engine)
session = Session()

hashed = hashlib.sha256(b"admin123").hexdigest()

from app.models.user import User

existing = session.query(User).filter(User.username == "admin").first()
if existing:
    print("Admin already exists")
else:
    admin = User(
        email="admin@omniconnect.com",
        username="admin",
        full_name="Administrador",
        role="admin",
        hashed_password=hashed,
        is_active=True
    )
    session.add(admin)
    session.commit()
    print(f"Admin created!")

session.close()