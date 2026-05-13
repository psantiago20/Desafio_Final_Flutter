import logging
from typing import Dict, Optional
import firebase_admin
from firebase_admin import credentials, messaging
import os

logger = logging.getLogger(__name__)

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        # Check if already initialized
        if not firebase_admin._apps:
            # For production/cloud environments, it automatically finds the credentials.
            # For local dev, you must set GOOGLE_APPLICATION_CREDENTIALS env var 
            # to point to your serviceAccountKey.json
            firebase_admin.initialize_app()
            logger.info("Firebase Admin initialized successfully.")
    except Exception as e:
        logger.warning(f"Failed to initialize Firebase Admin (this is expected if no credentials are set yet): {e}")

# Attempt to initialize on module load
initialize_firebase()

class FCMService:
    @staticmethod
    def send_notification(
        token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None
    ) -> bool:
        """Sends an FCM push notification to a specific device token."""
        if not token:
            logger.warning("FCM token is missing. Cannot send notification.")
            return False

        if not firebase_admin._apps:
            logger.warning("Firebase app not initialized. Skipping notification.")
            return False

        # Build payload
        notification = messaging.Notification(
            title=title,
            body=body,
        )
        
        # Ensure all data values are strings (FCM requirement)
        if data:
            data = {str(k): str(v) for k, v in data.items()}
            
        message = messaging.Message(
            notification=notification,
            data=data,
            token=token,
        )

        try:
            response = messaging.send(message)
            logger.info(f"Successfully sent FCM message: {response}")
            return True
        except Exception as e:
            logger.error(f"Error sending FCM message to token {token}: {e}")
            return False
            
fcm_service = FCMService()
