import pytest
from fastapi import status

def get_auth_headers(client, username, password):
    response = client.post(
        "/api/auth/login",
        data={"username": username, "password": password}
    )
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

def test_registration_uniqueness_constraints(client):
    # 1. Register a valid patient user
    user_data_1 = {
        "email": "user1@example.com",
        "username": "user1",
        "password": "password123",
        "full_name": "User One",
        "phone": "5511999999991",
        "role": "patient"
    }
    response = client.post("/api/auth/register", json=user_data_1)
    assert response.status_code == status.HTTP_201_CREATED

    # 2. Test duplicate email
    user_data_dup_email = {
        "email": "user1@example.com", # Duplicate
        "username": "user2",
        "password": "password123",
        "full_name": "User Two",
        "phone": "5511999999992",
        "role": "patient"
    }
    response = client.post("/api/auth/register", json=user_data_dup_email)
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert "Email already registered" in response.json()["detail"]

    # 3. Test duplicate username
    user_data_dup_username = {
        "email": "user2@example.com",
        "username": "user1", # Duplicate
        "password": "password123",
        "full_name": "User Two",
        "phone": "5511999999992",
        "role": "patient"
    }
    response = client.post("/api/auth/register", json=user_data_dup_username)
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert "Username already taken" in response.json()["detail"]

    # 4. Test duplicate phone
    user_data_dup_phone = {
        "email": "user2@example.com",
        "username": "user2",
        "password": "password123",
        "full_name": "User Two",
        "phone": "5511999999991", # Duplicate
        "role": "patient"
    }
    response = client.post("/api/auth/register", json=user_data_dup_phone)
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert "Phone number already registered" in response.json()["detail"]


def test_patient_cpf_uniqueness_constraints(client):
    # Register an admin user to perform patient operations
    admin_data = {
        "email": "admin@example.com",
        "username": "admin_user",
        "password": "adminpassword",
        "full_name": "Admin User",
        "phone": "5511888888888",
        "role": "admin"
    }
    response = client.post("/api/auth/register", json=admin_data)
    assert response.status_code == status.HTTP_201_CREATED
    headers = get_auth_headers(client, "admin_user", "adminpassword")

    # Create patient 1 with CPF
    patient_1 = {
        "name": "Patient One",
        "email": "patient1@example.com",
        "phone": "5511977777771",
        "cpf": "12345678901"
    }
    response = client.post("/api/patients", json=patient_1, headers=headers)
    assert response.status_code == status.HTTP_201_CREATED
    p1_id = response.json()["id"]

    # Create patient 2 with duplicate CPF (raw vs format testing)
    patient_2_dup = {
        "name": "Patient Two",
        "email": "patient2@example.com",
        "phone": "5511977777772",
        "cpf": "123.456.789-01" # Duplicate CPF (formatted)
    }
    response = client.post("/api/patients", json=patient_2_dup, headers=headers)
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert "CPF" in response.json()["detail"]

    # Create patient 3 with unique CPF
    patient_3 = {
        "name": "Patient Three",
        "email": "patient3@example.com",
        "phone": "5511977777773",
        "cpf": "98765432109"
    }
    response = client.post("/api/patients", json=patient_3, headers=headers)
    assert response.status_code == status.HTTP_201_CREATED
    p3_id = response.json()["id"]

    # Update patient 3 with duplicate CPF of patient 1
    patient_3_update = {
        "cpf": "12345678901" # Already used by patient 1
    }
    response = client.put(f"/api/patients/{p3_id}", json=patient_3_update, headers=headers)
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert "CPF" in response.json()["detail"]

    # Update patient 3 with its own CPF (should be allowed)
    patient_3_update_own = {
        "cpf": "987.654.321-09"
    }
    response = client.put(f"/api/patients/{p3_id}", json=patient_3_update_own, headers=headers)
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["cpf"] == "98765432109" # Cleaned/normalized
