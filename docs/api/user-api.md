# User API

## 1. Objective

Document the User Service API endpoints for profile management, social graph, and interest management.

## 2. Base URL

```
Gateway: http://localhost:8080/api/v1/users
Service: http://localhost:8082/api/v1/users
```

## 3. Endpoints

### 3.1 GET /{id}

Get user profile by ID.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "success": true,
  "message": "User found",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "maria.silva@usp.br",
    "fullName": "Maria Silva",
    "username": "maria.silva",
    "role": "STUDENT",
    "avatar": "https://storage.pitaya.com/avatars/user123.jpg",
    "banner": "https://storage.pitaya.com/banners/user123.jpg",
    "bio": "PhD candidate in Computer Science",
    "location": "São Paulo, SP",
    "institution": "Universidade de São Paulo",
    "course": "Computer Science",
    "semester": 8,
    "researchLine": "Natural Language Processing",
    "lattesUrl": "http://lattes.cnpq.br/1234567890",
    "orcid": "0000-0001-2345-6789",
    "githubUrl": "https://github.com/maria.silva",
    "linkedinUrl": "https://linkedin.com/in/maria.silva",
    "interests": ["AI", "Machine Learning", "NLP"],
    "followerCount": 150,
    "followingCount": 89,
    "postCount": 45,
    "isFollowing": false,
    "profileComplete": true,
    "createdAt": "2026-01-15T10:00:00Z"
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.2 GET /me

Get authenticated user's full profile.

**Headers:** `Authorization: Bearer <token>`

**Response (200):** Same as GET /{id} but for the authenticated user.

---

### 3.3 PUT /me

Update authenticated user's profile.

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "bio": "Updated bio text",
  "location": "Rio de Janeiro, RJ",
  "institution": "UFRJ",
  "course": "Data Science",
  "semester": 6,
  "researchLine": "Deep Learning",
  "lattesUrl": "http://lattes.cnpq.br/9876543210",
  "orcid": "0000-0002-9876-5432",
  "githubUrl": "https://github.com/maria.silva",
  "linkedinUrl": "https://linkedin.com/in/maria.silva"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "profileComplete": true
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.4 POST /me/avatar

Upload profile avatar.

**Headers:** `Authorization: Bearer <token>`, `Content-Type: multipart/form-data`

**Request:** Form-data with `file` field (image, max 5MB, JPEG/PNG/GIF/WEBP)

**Response (200):**
```json
{
  "success": true,
  "message": "Avatar updated",
  "data": {
    "avatarUrl": "https://storage.pitaya.com/avatars/user123-new.jpg"
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.5 POST /me/banner

Upload profile banner.

**Headers:** `Authorization: Bearer <token>`, `Content-Type: multipart/form-data`

**Request:** Form-data with `file` field (image, max 10MB, JPEG/PNG/WEBP, 1500x500)

**Response (200):** Similar to avatar upload.

---

### 3.6 PUT /me/interests

Update user interests.

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "interests": ["AI", "Machine Learning", "NLP", "Computer Vision"]
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Interests updated",
  "data": null,
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.7 GET /{id}/followers

Get user followers (paginated).

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `page` (int, default 0)
- `size` (int, default 20)

**Response (200):**
```json
{
  "success": true,
  "message": "Followers retrieved",
  "data": {
    "content": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "fullName": "João Oliveira",
        "username": "joao.oliveira",
        "avatar": "https://storage.pitaya.com/avatars/joao.jpg",
        "bio": "Professor at USP",
        "isFollowing": true
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 150,
    "totalPages": 8,
    "last": false
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.8 GET /{id}/following

Get users that a user is following (paginated).

**Headers:** `Authorization: Bearer <token>`

---

### 3.9 POST /{id}/follow

Follow a user.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "success": true,
  "message": "Now following user",
  "data": null,
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.10 DELETE /{id}/follow

Unfollow a user.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "success": true,
  "message": "Unfollowed user",
  "data": null,
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.11 GET /me/suggestions

Get suggested users to follow.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:** `limit` (int, default 5)

**Response (200):**
```json
{
  "success": true,
  "message": "Suggestions retrieved",
  "data": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440002",
      "fullName": "Ana Costa",
      "username": "ana.costa",
      "avatar": null,
      "bio": "Researcher in AI",
      "mutualFollowers": 12
    }
  ],
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.12 GET /interests

List all available interests.

**Response (200):**
```json
{
  "success": true,
  "message": "Interests retrieved",
  "data": [
    { "id": "uuid", "name": "Artificial Intelligence", "category": "TECHNOLOGY", "icon": "🤖" },
    { "id": "uuid", "name": "Medicine", "category": "HEALTH", "icon": "💊" },
    { "id": "uuid", "name": "Mathematics", "category": "SCIENCE", "icon": "📐" }
  ],
  "timestamp": "2026-05-14T12:00:00Z"
}
```

## 4. Events Produced

| Event | When |
|-------|------|
| PROFILE_UPDATED | Profile is updated |

## 5. Events Consumed

| Event | From | Action |
|-------|------|--------|
| USER_REGISTERED | Auth Service | Create profile record |
