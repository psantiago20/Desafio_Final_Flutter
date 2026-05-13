from dotenv import load_dotenv
import os
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
load_dotenv(os.path.join(os.path.dirname(__file__), '../../.env'))

from app.services.fcm_service import fcm_service

token = "cKXcDwAsSF2V0Z3O1Ea2Ux:APA91bHGsI_tmbyF_5XmuFgkuLM64zjNhbkrHpopI1uYgThIvNBjbNyNA_whHxW5V98qvv0UJYb3qfMc_mvJBlBwEgx29dhtjT31DniHmemVzXagarulxyQ"

result = fcm_service.send_notification(
    token=token,
    title="Test FCM",
    body="This is a test message from Antigravity!",
    data={"type": "test"}
)

print("FCM send result:", result)
