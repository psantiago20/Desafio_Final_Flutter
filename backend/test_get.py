from app.db.database import SessionLocal
from app.models.message import Message
from sqlalchemy.orm import joinedload

db = SessionLocal()
query = db.query(Message).options(joinedload(Message.patient))
query = query.filter(Message.patient_id == 15)
query = query.filter((Message.sender_id == 14) | (Message.receiver_id == 14))
query = query.filter((Message.sender_id.isnot(None)) | (Message.receiver_id.isnot(None)))
messages = query.order_by(Message.created_at.desc()).limit(10).all()
for m in messages:
    print(f'ID:{m.id} text:{m.content}')
