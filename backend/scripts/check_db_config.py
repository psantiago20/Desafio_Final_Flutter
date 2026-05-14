import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings
print(f"DATABASE_URL: {settings.DATABASE_URL}")
