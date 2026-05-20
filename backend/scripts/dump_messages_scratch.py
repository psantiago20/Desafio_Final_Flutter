import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import SessionLocal
from app.models.message import Message

def dump_messages():
    db = SessionLocal()
    try:
        messages = db.query(Message).order_by(Message.id.asc()).all()
        print(f"Total messages: {len(messages)}")
        for m in messages:
            print(f"ID: {m.id} | Patient: {m.patient_id} | Sender: {m.sender_id} | Receiver: {m.receiver_id} | Source: {m.source} | Content: {repr(m.content)}")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    dump_messages()
