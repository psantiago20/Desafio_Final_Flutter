# Mentorship API

## 1. Objective

Document the Mentorship Service API endpoints for managing mentorship programs, scheduling sessions, and collecting feedback.

## 2. Base URL

```
Gateway: http://localhost:8080/api/v1/mentorships
Service: http://localhost:8086/api/v1/mentorships
```

## 3. Endpoints

### 3.1 POST /

Create a new mentorship request.

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "mentorId": "uuid-of-mentor",
  "title": "Orientação em NLP para TCC",
  "description": "Preciso de orientação para meu TCC sobre Processamento de Linguagem Natural.",
  "maxSessions": 8
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Mentorship request created",
  "data": {
    "id": "mentorship-uuid",
    "mentor": {
      "id": "uuid",
      "fullName": "Prof. Carlos Santos",
      "username": "carlos.santos",
      "avatar": null
    },
    "status": "PENDING",
    "title": "Orientação em NLP para TCC",
    "createdAt": "2026-05-14T12:00:00Z"
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.2 GET /{id}

Get mentorship details.

**Headers:** `Authorization: Bearer <token>`

---

### 3.3 PUT /{id}/accept

Accept a mentorship request (mentor only).

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "success": true,
  "message": "Mentorship accepted",
  "data": { "status": "ACTIVE" },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.4 PUT /{id}/reject

Reject a mentorship request (mentor only).

---

### 3.5 PUT /{id}/complete

Mark mentorship as completed.

---

### 3.6 PUT /{id}/cancel

Cancel a mentorship.

---

### 3.7 GET /mine

List user's mentorships.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `role` (string: mentor | mentee, optional)
- `status` (string: PENDING | ACTIVE | COMPLETED | CANCELLED, optional)
- `page`, `size`

**Response (200):**
```json
{
  "success": true,
  "message": "Mentorships retrieved",
  "data": {
    "content": [
      {
        "id": "uuid",
        "title": "Orientação em NLP para TCC",
        "mentor": { "id": "uuid", "fullName": "Carlos Santos" },
        "mentee": { "id": "uuid", "fullName": "Maria Silva" },
        "status": "ACTIVE",
        "sessionsCompleted": 3,
        "totalSessions": 8,
        "createdAt": "2026-05-01T10:00:00Z"
      }
    ]
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.8 POST /{id}/sessions

Schedule a mentorship session.

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "title": "Revisão do Capítulo 3",
  "description": "Revisar o capítulo sobre metodologia",
  "scheduledAt": "2026-05-20T14:00:00Z",
  "durationMinutes": 60,
  "meetingLink": "https://meet.google.com/abc-defg-hij"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Session scheduled",
  "data": {
    "id": "session-uuid",
    "title": "Revisão do Capítulo 3",
    "scheduledAt": "2026-05-20T14:00:00Z",
    "durationMinutes": 60,
    "status": "SCHEDULED",
    "meetingLink": "https://meet.google.com/abc-defg-hij"
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.9 PUT /sessions/{id}/confirm

Confirm a session (mentor).

---

### 3.10 PUT /sessions/{id}/complete

Complete a session (mentor).

**Request:**
```json
{
  "mentorNotes": "Progresso significativo. Próximo passo: implementação do modelo."
}
```

---

### 3.11 PUT /sessions/{id}/cancel

Cancel a session.

---

### 3.12 POST /sessions/{id}/feedback

Submit session feedback (mentee).

**Request:**
```json
{
  "rating": 5,
  "feedback": "Sessão muito produtiva! O mentor foi muito claro nas explicações."
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Feedback submitted",
  "data": null,
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.13 GET /available

List available mentors.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `interest` (string, optional)
- `page`, `size`

**Response (200):**
```json
{
  "success": true,
  "message": "Available mentors",
  "data": {
    "content": [
      {
        "id": "uuid",
        "fullName": "Prof. Carlos Santos",
        "username": "carlos.santos",
        "avatar": null,
        "bio": "Professor de Ciência da Computação na USP",
        "institution": "USP",
        "researchLine": "Natural Language Processing",
        "rating": 4.8,
        "mentorshipCount": 15,
        "interests": ["AI", "NLP", "Machine Learning"]
      }
    ]
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

## 4. Status Flow

```
PENDING → ACTIVE → COMPLETED
  ↓         ↓
CANCELLED  CANCELLED
```

Session Status:
```
SCHEDULED → CONFIRMED → IN_PROGRESS → COMPLETED
    ↓          ↓            ↓
CANCELLED   CANCELLED     CANCELLED
```

## 5. Events Produced

| Event | When |
|-------|------|
| MENTORSHIP_SCHEDULED | Session scheduled |

## 6. Rate Limits

| Endpoint | Limit |
|----------|-------|
| POST / (create mentorship) | 10/day per user |
| POST /{id}/sessions | 5/day per mentorship |
| POST /sessions/{id}/feedback | 1 per session |
