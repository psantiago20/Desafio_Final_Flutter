# Post API

## 1. Objective

Document the Post Service API endpoints for creating, reading, and interacting with posts, comments, likes, reposts, and timeline management.

## 2. Base URL

```
Gateway: http://localhost:8080/api/v1/posts
Service: http://localhost:8083/api/v1/posts
```

## 3. Endpoints

### 3.1 POST /

Create a new post.

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "content": "Acabei de publicar meu novo artigo sobre #MachineLearning! Link na bio.",
  "imageUrl": null,
  "visibility": "PUBLIC"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Post created",
  "data": {
    "id": "a1b2c3d4-...",
    "content": "Acabei de publicar meu novo artigo sobre #MachineLearning! Link na bio.",
    "imageUrl": null,
    "visibility": "PUBLIC",
    "likeCount": 0,
    "commentCount": 0,
    "repostCount": 0,
    "isLiked": false,
    "isReposted": false,
    "author": {
      "id": "550e8400-...",
      "fullName": "Maria Silva",
      "username": "maria.silva",
      "avatar": null
    },
    "hashtags": ["MachineLearning"],
    "createdAt": "2026-05-14T12:00:00Z"
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.2 GET /{id}

Get post by ID.

**Headers:** `Authorization: Bearer <token>`

**Response (200):** Same structure as POST response but with comments included.

---

### 3.3 DELETE /{id}

Delete a post (only author or admin).

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "success": true,
  "message": "Post deleted",
  "data": null,
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.4 GET /timeline

Get the authenticated user's timeline (following + own posts).

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `page` (int, default 0)
- `size` (int, default 20)
- `sort` (string: latest | trending, default latest)

**Response (200):**
```json
{
  "success": true,
  "message": "Timeline retrieved",
  "data": {
    "content": [
      {
        "id": "post-uuid",
        "content": "Post content...",
        "author": { "...": "..." },
        "likeCount": 42,
        "commentCount": 7,
        "hashtags": ["AI"],
        "createdAt": "2026-05-14T11:00:00Z"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 200,
    "totalPages": 10,
    "last": false
  },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.5 GET /user/{userId}

Get posts by a specific user.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:** `page`, `size`

---

### 3.6 GET /trending

Get trending hashtags.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:** `limit` (int, default 10)

**Response (200):**
```json
{
  "success": true,
  "message": "Trending topics",
  "data": [
    { "name": "MachineLearning", "postCount": 1250 },
    { "name": "AI", "postCount": 980 },
    { "name": "DeepLearning", "postCount": 765 }
  ],
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.7 POST /{id}/like

Like a post.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "success": true,
  "message": "Post liked",
  "data": { "likeCount": 43 },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.8 DELETE /{id}/like

Unlike a post.

**Headers:** `Authorization: Bearer <token>`

---

### 3.9 POST /{id}/repost

Repost a post.

**Headers:** `Authorization: Bearer <token>`

**Request (optional):**
```json
{
  "content": "Adicionando meu comentário ao compartilhar..."
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Post reposted",
  "data": { "repostCount": 5 },
  "timestamp": "2026-05-14T12:00:00Z"
}
```

---

### 3.10 DELETE /{id}/repost

Remove repost.

---

### 3.11 POST /{id}/comments

Add a comment to a post.

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "content": "Excelente artigo! Muito relevante para minha pesquisa.",
  "parentCommentId": null
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Comment added",
  "data": {
    "id": "comment-uuid",
    "content": "Excelente artigo! Muito relevante para minha pesquisa.",
    "author": {
      "id": "user-uuid",
      "fullName": "João Oliveira",
      "username": "joao.oliveira",
      "avatar": null
    },
    "createdAt": "2026-05-14T12:05:00Z"
  },
  "timestamp": "2026-05-14T12:05:00Z"
}
```

---

### 3.12 GET /{id}/comments

Get comments for a post (paginated).

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:** `page`, `size`

---

### 3.13 GET /hashtag/{name}

Get posts by hashtag.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:** `page`, `size`

---

### 3.14 GET /explore

Get explore page content (popular + recent posts from broader network).

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:** `page`, `size`

## 4. Events Produced

| Event | When |
|-------|------|
| POST_CREATED | Post published |
| COMMENT_ADDED | Comment added |
| POST_LIKED | Post liked |

## 5. Events Consumed

| Event | From | Action |
|-------|------|--------|
| PROFILE_UPDATED | User Service | Update cached author info |
