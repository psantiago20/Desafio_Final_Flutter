from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta

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
    
    # Se for paciente, cria perfil de paciente
    elif user.role == "patient":
        from app.models.patient import Patient
        db_patient = Patient(
            user_id=db_user.id,
            name=user.full_name or user.username,
            email=user.email,
            phone=phone_clean,
            whatsapp=phone_clean, # O número do celular será o WhatsApp
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


@router.get("/me", response_model=UserResponse)
def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user