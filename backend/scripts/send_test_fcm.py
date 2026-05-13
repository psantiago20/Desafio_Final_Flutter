import sys
import os
from sqlalchemy.orm import Session

# Add the parent directory to sys.path so we can import 'app'
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), '../../.env'))

from app.db.database import SessionLocal
from app.models.user import User
from app.services.fcm_service import fcm_service

def send_test_message(username: str):
    db: Session = SessionLocal()
    try:
        user = db.query(User).filter(User.username == username).first()
        if not user:
            print(f"User '{username}' not found.")
            return

        if not user.fcm_token:
            print(f"User '{username}' does not have an FCM token registered. Did you log in to the app with this user?")
            return

        print(f"Found FCM Token for user '{username}': {user.fcm_token[:15]}...")
        
        result = fcm_service.send_notification(
            token=user.fcm_token,
            title="OmniConnect Test",
            body=f"Hello {user.full_name or username}! Your Firebase Messaging is working! 🎉",
            data={"type": "test", "test_id": "123"}
        )
        
        if result:
            print("✅ Push notification sent successfully!")
        else:
            print("❌ Failed to send push notification.")
            
    finally:
        db.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python send_test_fcm.py <username>")
        print("Example: python send_test_fcm.py joao.silva")
        sys.exit(1)
        
    target_username = sys.argv[1]
    send_test_message(target_username)
