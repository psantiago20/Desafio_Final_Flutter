from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta
from pydantic import BaseModel

from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse, Token, LoginRequest
from app.services.auth_service import verify_password, get_password_hash, create_access_token, decode_token
from app.core.config import settings

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_token(token)
    if payload is None:
        raise credentials_exception
    user_id_str = payload.get("sub")
    if user_id_str is None:
        raise credentials_exception
    user_id = int(user_id_str)
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_exception
    return user


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    db_user = db.query(User).filter(User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already taken")
    
    # Normalizar o telefone: remover caracteres não numéricos e garantir o prefixo 55
    phone_clean = "".join(filter(str.isdigit, user.phone))
    if not phone_clean.startswith("55") and len(phone_clean) >= 10:
        phone_clean = "55" + phone_clean
    
    # 3. Verificar se o telefone já está em uso por outro User
    db_user = db.query(User).filter(User.phone == phone_clean).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Phone number already registered")

    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email,
        username=user.username,
        full_name=user.full_name,
        phone=phone_clean,
        role=user.role,
        hashed_password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    # Se for médico, cria perfil de médico
    if user.role == "doctor":
        from app.models.medico import Medico
        db_medico = Medico(
            nome_completo=user.full_name or user.username,
            crm=user.crm or "PENDENTE",
            crm_estado="SP", # Default para SP ou extrair do CRM se formatado
            especialidade=user.specialty or "Clínica Geral",
            email=user.email,
            telefone=phone_clean,
            whatsapp=phone_clean,
            user_id=db_user.id
        )
        db.add(db_medico)
        db.commit()
    
    # Se for paciente, vincula ou cria perfil de paciente
    elif user.role == "patient":
        from app.models.patient import Patient
        from app.utils.phone_utils import find_patient_by_exact_messaging_phone
        
        # Tenta localizar paciente pré-existente (ex: vindo do WhatsApp)
        existing_patient = find_patient_by_exact_messaging_phone(db, phone_clean)
        
        if existing_patient:
            # Vincula o usuário ao paciente existente
            existing_patient.user_id = db_user.id
            # Atualiza dados se estiverem genéricos
            if existing_patient.name.startswith("WhatsApp User") or existing_patient.name.startswith("App User"):
                existing_patient.name = user.full_name or user.username
            if not existing_patient.email:
                existing_patient.email = user.email
            db.add(existing_patient)
        else:
            # Cria novo paciente
            db_patient = Patient(
                user_id=db_user.id,
                name=user.full_name or user.username,
                email=user.email,
                phone=phone_clean,
                whatsapp=phone_clean,
            )
            db.add(db_patient)
        
        db.commit()

    return db_user



@router.post("/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(
        (User.username == form_data.username) | (User.email == form_data.username)
    ).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id), "role": user.role}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/refresh", response_model=Token)
def refresh_token(current_user: User = Depends(get_current_user)):
    """
    Renova o token para usuários ativos.
    """
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(current_user.id), "role": current_user.role}, 
        expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserResponse)
def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user

class FCMTokenUpdate(BaseModel):
    fcm_token: str

@router.patch("/fcm-token", status_code=status.HTTP_204_NO_CONTENT)
def update_fcm_token(
    payload: FCMTokenUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    current_user.fcm_token = payload.fcm_token
    db.commit()
    return None
