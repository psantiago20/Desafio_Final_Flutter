import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import SessionLocal
from app.models.message import Message
from app.models.user import User

def simulate_frontend():
    db = SessionLocal()
    try:
        # Fetch patient and doctor to know IDs
        patient_user_id = 12
        doctor_user_ids = [8, 9, 10, 11] # marina.costa=8, thorne.blackwood=9, ana.costa=10, ricardo.mello=11
        
        # Load medicos list (mocking medicosProvider)
        # In Flutter: doc.nomeCompleto and doc.fotoUrl
        medicos = {
            8: {"nomeCompleto": "Dra. Marina Costa", "fotoUrl": None},
            9: {"nomeCompleto": "Dr. Thorne Blackwood", "fotoUrl": None},
            10: {"nomeCompleto": "Dra. Ana Costa", "fotoUrl": None},
            11: {"nomeCompleto": "Dr. Ricardo Mello", "fotoUrl": None},
        }

        # Fetch messages in descending order (matching API)
        messages_from_db = db.query(Message).order_by(Message.created_at.desc()).limit(100).all()
        
        # In Flutter, msgs is iterated in reversed order: for m in msgs.reversed
        messages_reversed = list(reversed(messages_from_db))

        loaded_messages = []
        isis_messages = []
        doctor_messages = []

        for m in messages_reversed:
            source = m.source
            wa_from = m.wa_from
            sender_id = m.sender_id
            
            is_me = False
            if sender_id is not None:
                is_me = (sender_id == patient_user_id)
            elif source == 'app':
                is_me = True
            elif source == 'whatsapp':
                # role is patient
                is_me = True
            else:
                is_me = False

            sender_name = None
            if not is_me:
                if wa_from == 'isis_ia' or source == 'system' or source == 'ai' or source == 'bot':
                    sender_name = 'Isis (Assistente)'
                else:
                    sender_name = 'Médico'
                    if sender_id is not None:
                        if sender_id in medicos:
                            sender_name = medicos[sender_id]["nomeCompleto"]

            chat_msg = {
                "id": m.id,
                "text": m.content,
                "isMe": is_me,
                "senderName": sender_name,
                "source": source
            }

            loaded_messages.append(chat_msg)

            # Classification logic:
            is_explicitly_doctor = (source == 'app_doctor') or (
                not is_me and sender_name is not None and sender_name != 'Isis (Assistente)'
            )

            is_isis = (
                wa_from == 'isis_ia' or
                source == 'system' or source == 'ai' or source == 'bot' or
                (not is_me and sender_name == 'Isis (Assistente)') or
                is_me
            ) and source != 'app_doctor'

            if is_isis:
                isis_messages.append(chat_msg)
            else:
                doctor_messages.append(chat_msg)

        print(f"Total processed: {len(loaded_messages)}")
        print(f"Isis messages count: {len(isis_messages)}")
        print(f"Doctor messages count: {len(doctor_messages)}")
        
        if isis_messages:
            last_isis = isis_messages[-1]
            print(f"Last Isis Message: ID {last_isis['id']} | Content: {repr(last_isis['text'])}")
        else:
            print("Last Isis Message: None")
            
        if doctor_messages:
            last_doc = doctor_messages[-1]
            print(f"Last Doctor Message: ID {last_doc['id']} | Content: {repr(last_doc['text'])}")
        else:
            print("Last Doctor Message: None")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    simulate_frontend()
