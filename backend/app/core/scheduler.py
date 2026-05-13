import asyncio
import logging
from datetime import datetime, timedelta
from app.db.database import SessionLocal
from app.models.appointment import Appointment
from app.models.user import User
from app.models.patient import Patient
from app.services.fcm_service import fcm_service

logger = logging.getLogger(__name__)

async def check_appointments_task():
    """Runs periodically to send reminders for upcoming appointments."""
    logger.info("Appointment reminder scheduler started.")
    while True:
        db = SessionLocal()
        try:
            now = datetime.utcnow()
            
            # The scheduler runs every minute. 
            # We look for appointments that are exactly between 24h and 24h + 1m away
            # And appointments between 72h and 72h + 1m away.
            
            target_24h_start = now + timedelta(hours=24)
            target_24h_end = target_24h_start + timedelta(minutes=1)
            
            target_72h_start = now + timedelta(hours=72)
            target_72h_end = target_72h_start + timedelta(minutes=1)

            # Query 24h reminders
            reminders_24h = db.query(Appointment).filter(
                Appointment.status == "confirmed",
                Appointment.appointment_date >= target_24h_start,
                Appointment.appointment_date < target_24h_end
            ).all()

            # Query 72h reminders
            reminders_72h = db.query(Appointment).filter(
                Appointment.status == "confirmed",
                Appointment.appointment_date >= target_72h_start,
                Appointment.appointment_date < target_72h_end
            ).all()

            for appointment in reminders_24h + reminders_72h:
                is_24h = appointment in reminders_24h
                time_str = "24 hours" if is_24h else "72 hours"
                
                patient = db.query(Patient).filter(Patient.id == appointment.patient_id).first()
                if not patient or not patient.user_id:
                    continue
                
                user = db.query(User).filter(User.id == patient.user_id).first()
                if not user or not user.fcm_token:
                    continue

                doctor = db.query(User).filter(User.id == appointment.doctor_id).first()
                doctor_name = doctor.full_name if doctor else "your doctor"

                formatted_time = appointment.appointment_date.strftime("%Y-%m-%d %H:%M")
                
                logger.info(f"Sending {time_str} reminder for appointment {appointment.id} to user {user.id}")
                
                fcm_service.send_notification(
                    token=user.fcm_token,
                    title="Appointment Reminder",
                    body=f"You have an appointment with {doctor_name} in {time_str} ({formatted_time}).",
                    data={
                        "type": "appointment_reminder",
                        "appointment_id": str(appointment.id)
                    }
                )

        except Exception as e:
            logger.error(f"Error in appointment background task: {e}")
        finally:
            db.close()
            
        await asyncio.sleep(60) # Run every minute

def start_scheduler():
    asyncio.create_task(check_appointments_task())
