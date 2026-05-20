import pytest
from fastapi import status
from app.services.agent_tools import execute_tool
from app.models.patient import Patient
from app.models.appointment import Appointment
from datetime import datetime

def get_auth_headers(client, username, password):
    response = client.post(
        "/api/auth/login",
        data={"username": username, "password": password}
    )
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

def test_endpoint_rbac_and_privacy(client, db):
    # 1. Register two patient users
    user_p1 = {
        "email": "p1@example.com",
        "username": "patient1",
        "password": "password123",
        "full_name": "Patient One",
        "phone": "5511999999901",
        "role": "patient"
    }
    user_p2 = {
        "email": "p2@example.com",
        "username": "patient2",
        "password": "password123",
        "full_name": "Patient Two",
        "phone": "5511999999902",
        "role": "patient"
    }
    
    assert client.post("/api/auth/register", json=user_p1).status_code == status.HTTP_201_CREATED
    assert client.post("/api/auth/register", json=user_p2).status_code == status.HTTP_201_CREATED

    headers_p1 = get_auth_headers(client, "patient1", "password123")
    headers_p2 = get_auth_headers(client, "patient2", "password123")

    # Access `/api/patients/me` to link/create the Patient record in the DB
    resp1 = client.get("/api/patients/me", headers=headers_p1)
    assert resp1.status_code == 200
    p1_id = resp1.json()["id"]

    resp2 = client.get("/api/patients/me", headers=headers_p2)
    assert resp2.status_code == 200
    p2_id = resp2.json()["id"]

    # 2. Patient 1 tries to list all patients -> 403 Forbidden
    assert client.get("/api/patients", headers=headers_p1).status_code == status.HTTP_403_FORBIDDEN

    # 3. Patient 1 tries to create a patient -> 403 Forbidden
    assert client.post("/api/patients", json={"name": "Attacker", "phone": "123"}, headers=headers_p1).status_code == status.HTTP_403_FORBIDDEN

    # 4. Patient 1 tries to read Patient 2's profile -> 403 Forbidden
    assert client.get(f"/api/patients/{p2_id}", headers=headers_p1).status_code == status.HTTP_403_FORBIDDEN

    # 5. Patient 1 tries to update Patient 2's profile -> 403 Forbidden
    assert client.put(f"/api/patients/{p2_id}", json={"name": "Hacked"}, headers=headers_p1).status_code == status.HTTP_403_FORBIDDEN

    # 6. Patient 1 tries to delete Patient 2's profile -> 403 Forbidden
    assert client.delete(f"/api/patients/{p2_id}", headers=headers_p1).status_code == status.HTTP_403_FORBIDDEN

    # 7. Patient 1 accesses/updates their OWN profile -> 200 OK
    assert client.get(f"/api/patients/{p1_id}", headers=headers_p1).status_code == 200
    assert client.put(f"/api/patients/{p1_id}", json={"name": "Patient One Updated"}, headers=headers_p1).status_code == 200


def test_agent_tools_level_authorization(db):
    from app.models.user import User
    # Setup Doctor User
    doc = User(id=99, username="doctor_test", email="doc_test@example.com", hashed_password="pw", role="doctor")
    db.add(doc)
    db.commit()

    # Setup Patient 1 and Patient 2 in DB
    p1 = Patient(name="Patient One", email="p1@example.com", phone="5511999999901", cpf="11111111111", is_active=True)
    p2 = Patient(name="Patient Two", email="p2@example.com", phone="5511999999902", cpf="22222222222", is_active=True)
    db.add_all([p1, p2])
    db.commit()

    # Add a mock appointment for Patient 1
    appt1 = Appointment(patient_id=p1.id, doctor_id=doc.id, appointment_date=datetime.now(), status="confirmed", reason="Checkup")
    # Add a mock appointment for Patient 2
    appt2 = Appointment(patient_id=p2.id, doctor_id=doc.id, appointment_date=datetime.now(), status="confirmed", reason="Secret Surgery")
    db.add_all([appt1, appt2])
    db.commit()

    # Case A: Patient attempts to use 'buscar_info_paciente' -> should be rejected
    res = execute_tool(
        tool_name="buscar_info_paciente",
        arguments={"nome_ou_cpf": "22222222222"},
        db=db,
        user_role="patient"
    )
    assert "Acesso não autorizado" in res

    # Case B: Patient attempts to use 'buscar_consultas_medico' -> should be rejected
    res = execute_tool(
        tool_name="buscar_consultas_medico",
        arguments={"medico_id": 1},
        db=db,
        user_role="patient"
    )
    assert "Acesso não autorizado" in res

    # Case C: Patient attempts to use 'buscar_agendamentos' with other patient's CPF, but with their own patient_id
    # Inside the logic, it should force the query to only return Patient 1's appointments, or fail.
    res = execute_tool(
        tool_name="buscar_agendamentos",
        arguments={"cpf": "22222222222"}, # Attacker requests Patient 2's CPF
        db=db,
        patient_id=p1.id,
        user_role="patient"
    )
    # The output should belong to Patient One, NOT Patient Two
    assert "Patient One" in res or "Patient One Updated" in res
    assert "Patient Two" not in res
    assert "Secret Surgery" not in res

    # Case D: Staff user (e.g. doctor) uses 'buscar_info_paciente' -> should succeed
    res = execute_tool(
        tool_name="buscar_info_paciente",
        arguments={"nome_ou_cpf": "22222222222"},
        db=db,
        user_role="doctor"
    )
    assert "Acesso não autorizado" not in res
    assert "Patient Two" in res
