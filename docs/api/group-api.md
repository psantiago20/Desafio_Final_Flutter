# Group API

## 1. Objective

Document the Group Service API endpoints for creating and managing study groups, member roles, and invitations.

## 2. Base URL

```
Gateway: http://localhost:8080/api/v1/groups
Service: http://localhost:8084/api/v1/groups
```

## 3. Endpoints

### 3.1 POST /

Create a new study group.

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "name": "AI Study Group - 2026",
  "description": "Grupo dedicado ao estudo de Inteligência Artificial e Machine Learning.",
  "category": "TECHNOLOGY",
  "visibility": "PUBLIC"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Group created",
  "data": {
    "id": "group-uuid",
    "name": "AI Study Group - 2026",
    "description": "Grupo dedicado ao estudo de Inteligência Artificial e Machine Learning.",
    "category": "TECHNOLOGY",
    "visibility": "PUBLIC",
    "memberCount": 1,
    "role": "OWNER",
    "createdAt": "2026-05-14T12:00:00Z"
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.2 GET /{id}

Get group details.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "success": true,
  "message": "Group found",
  "data": {
    "id": "group-uuid",
    "name": "AI Study Group - 2026",
    "description": "Grupo dedicado ao estudo de IA e ML.",
    "bannerUrl": null,
    "category": "TECHNOLOGY",
    "visibility": "PUBLIC",
    "owner": { "id": "uuid", "fullName": "Maria Silva", "username": "maria.silva" },
    "memberCount": 25,
    "isMember": true,
    "memberRole": "MEMBER",
    "createdAt": "2026-05-14T12:00:00Z"
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.3 PUT /{id}

Update group settings (OWNER or ADMIN only).

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "name": "AI Study Group",
  "description": "Updated description",
  "visibility": "PRIVATE"
}
```

---

### 3.4 DELETE /{id}

Delete group (OWNER only).

---

### 3.5 GET /

List groups (paginated, filterable).

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `page` (int, default 0)
- `size` (int, default 20)
- `category` (string, optional)
- `search` (string, optional)

**Response (200):**
```json
{
  "success": true,
  "message": "Groups retrieved",
  "data": {
    "content": [
      {
        "id": "uuid",
        "name": "AI Study Group",
        "description": "Group description...",
        "category": "TECHNOLOGY",
        "memberCount": 25,
        "isMember": false
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 50,
    "totalPages": 3
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.6 GET /my

List groups the authenticated user is a member of.

**Headers:** `Authorization: Bearer <token>`

---

### 3.7 POST /{id}/join

Join a public group.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "success": true,
  "message": "Joined group",
  "data": { "role": "MEMBER" },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.8 POST /{id}/leave

Leave a group.

---

### 3.9 POST /{id}/invite

Invite a user to the group.

**Headers:** `Authorization: Bearer <token>` (OWNER, ADMIN, or MODERATOR)

**Request:**
```json
{
  "userId": "uuid-of-user-to-invite"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Invitation sent",
  "data": { "inviteId": "uuid" },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.10 POST /invites/{id}/accept

Accept a group invitation.

---

### 3.11 POST /invites/{id}/reject

Reject a group invitation.

---

### 3.12 GET /{id}/members

List group members.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:** `role` (string, optional filter)

**Response (200):**
```json
{
  "success": true,
  "message": "Members retrieved",
  "data": {
    "content": [
      {
        "id": "uuid",
        "fullName": "Maria Silva",
        "username": "maria.silva",
        "avatar": null,
        "role": "OWNER",
        "joinedAt": "2026-05-14T12:00:00Z"
      }
    ]
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.13 PUT /{groupId}/members/{userId}/role

Update member role (OWNER only).

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "role": "MODERATOR"
}
```

---

### 3.14 DELETE /{groupId}/members/{userId}

Remove member from group (OWNER or ADMIN).

## 4. Roles & Permissions

| Permission | OWNER | ADMIN | MODERATOR | MEMBER |
|-----------|-------|-------|-----------|--------|
| Update group | ✓ | ✓ | ✗ | ✗ |
| Delete group | ✓ | ✗ | ✗ | ✗ |
| Invite members | ✓ | ✓ | ✓ | ✗ |
| Remove members | ✓ | ✓ | ✗ | ✗ |
| Update roles | ✓ | ✓ | ✗ | ✗ |
| Moderate content | ✓ | ✓ | ✓ | ✗ |
| View content | ✓ | ✓ | ✓ | ✓ |
| Post content | ✓ | ✓ | ✓ | ✓ |

## 5. Events Produced

| Event | When |
|-------|------|
| GROUP_CREATED | Group successfully created |
