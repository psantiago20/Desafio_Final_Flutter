# Auth API

## 1. Objective

Document the Authentication Service API endpoints for user registration, login, token management, and password recovery.

## 2. Base URL

```
Production: https://api.pitaya.com/api/v1/auth
Local:      http://localhost:8081/api/v1/auth
Gateway:    http://localhost:8080/api/v1/auth
```

## 3. Endpoints

### 3.1 POST /register

Register a new user account.

**Request:**
```json
{
  "email": "maria.silva@usp.br",
  "password": "SenhaForte123",
  "confirmPassword": "SenhaForte123",
  "fullName": "Maria Silva",
  "username": "maria.silva",
  "birthDate": "2000-05-14",
  "role": "STUDENT"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "accessToken": "eyJhbGciOiJSUzI1NiJ9...",
    "refreshToken": "eyJhbGciOiJSUzI1NiJ9...",
    "tokenType": "Bearer",
    "expiresIn": 3600,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "maria.silva@usp.br",
      "fullName": "Maria Silva",
      "username": "maria.silva",
      "role": "STUDENT",
      "avatar": null
    }
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

**Validation Rules:**

| Field | Rule |
|-------|------|
| email | Valid email format, max 100 chars, unique |
| password | 8-100 chars, uppercase, lowercase, number |
| confirmPassword | Must match password |
| fullName | 1-150 chars |
| username | 3-50 chars, alphanumeric + ._- |
| birthDate | Must be past date, user must be 13+ |
| role | One of: STUDENT, PROFESSOR, RESEARCHER, MENTOR |

**Errors:**

| Status | Message |
|--------|---------|
| 400 | Email already registered |
| 400 | Username already taken |
| 400 | Validation failed |
| 422 | Invalid role |

---

### 3.2 POST /login

Authenticate with email and password.

**Request:**
```json
{
  "email": "maria.silva@usp.br",
  "password": "SenhaForte123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "accessToken": "eyJhbGciOiJSUzI1NiJ9...",
    "refreshToken": "eyJhbGciOiJSUzI1NiJ9...",
    "tokenType": "Bearer",
    "expiresIn": 3600,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "maria.silva@usp.br",
      "fullName": "Maria Silva",
      "username": "maria.silva",
      "role": "STUDENT",
      "avatar": null
    }
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

**Errors:**

| Status | Message |
|--------|---------|
| 400 | Invalid credentials |
| 401 | Account is disabled |
| 429 | Too many login attempts |

**Rate Limit:** 5 attempts per minute per IP.

---

### 3.3 POST /refresh

Refresh the access token using a refresh token.

**Request:**
```json
{
  "refreshToken": "eyJhbGciOiJSUzI1NiJ9..."
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "accessToken": "eyJhbGciOiJSUzI1NiJ9...",
    "refreshToken": "eyJhbGciOiJSUzI1NiJ9...",
    "tokenType": "Bearer",
    "expiresIn": 3600
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

**Errors:**

| Status | Message |
|--------|---------|
| 400 | Invalid refresh token |
| 401 | Refresh token expired |
| 401 | Refresh token revoked |

---

### 3.4 POST /forgot-password

Request a password reset email.

**Request:**
```json
{
  "email": "maria.silva@usp.br"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "If the email exists, a reset link has been sent",
  "data": null,
  "timestamp": "2026-05-14T12:00:00Z"
}
```

Note: Always returns success to prevent email enumeration.

---

### 3.5 POST /reset-password

Reset password using the token from email.

**Request:**
```json
{
  "token": "reset-token-from-email",
  "newPassword": "NovaSenhaForte456",
  "confirmPassword": "NovaSenhaForte456"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password reset successfully",
  "data": null,
  "timestamp": "2026-05-14T12:00:00Z"
}
```

**Errors:**

| Status | Message |
|--------|---------|
| 400 | Invalid or expired token |
| 400 | Password validation failed |

---

### 3.6 POST /logout

Invalidate the current refresh token.

**Headers:** `Authorization: Bearer <accessToken>`

**Request:**
```json
{
  "refreshToken": "eyJhbGciOiJSUzI1NiJ9..."
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully",
  "data": null,
  "timestamp": "2026-05-14T12:00:00Z"
}
```

## 4. Public Endpoints (No Auth Required)

| Endpoint | Method | Rate Limit |
|----------|--------|------------|
| /register | POST | 3/hour |
| /login | POST | 5/minute |
| /refresh | POST | 10/minute |
| /forgot-password | POST | 3/hour |
| /reset-password | POST | 3/hour |

## 5. Security Headers Required

```
Content-Type: application/json
```

## 6. Events Produced

| Event | When | Payload |
|-------|------|---------|
| USER_REGISTERED | After successful registration | email, fullName, username, role |
