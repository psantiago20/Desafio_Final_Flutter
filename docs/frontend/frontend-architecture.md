# Frontend Architecture

## 1. Objective

Document the frontend architecture of the Pitaya platform, built with pure HTML5, CSS3, and Vanilla JavaScript — no frameworks, focusing on modularity, maintainability, and performance.

## 2. Technology Stack

| Technology | Purpose |
|------------|---------|
| HTML5 | Semantic markup with ARIA accessibility |
| CSS3 | Styling with custom properties, Grid, Flexbox |
| JavaScript (ES6+) | Application logic, modular architecture |
| Fetch API | HTTP communication with backend |
| LocalStorage / SessionStorage | Client-side state persistence |
| Web Components (optional) | Reusable custom elements |

## 3. Project Structure

```
frontend/
├── index.html                    # Entry point SPA
├── pages/                        # Full page templates
│   ├── login.html
│   ├── register.html
│   ├── feed.html
│   ├── profile.html
│   ├── profile-edit.html
│   ├── post-detail.html
│   ├── groups.html
│   ├── group-detail.html
│   ├── library.html
│   ├── mentorship.html
│   ├── mentorship-session.html
│   ├── notifications.html
│   ├── settings.html
│   ├── admin.html
│   └── 404.html
│
├── css/
│   ├── main.css                  # Global styles, variables
│   ├── reset.css                 # CSS reset / normalize
│   ├── themes.css                # Dark/Light theme variables
│   ├── components.css            # Component styles
│   ├── layout.css                # Grid, flex layout
│   ├── responsive.css            # Media queries
│   └── pages/                    # Page-specific styles
│       ├── auth.css
│       ├── feed.css
│       ├── profile.css
│       ├── groups.css
│       └── admin.css
│
├── js/
│   ├── app.js                    # Main app initialization
│   ├── router.js                 # SPA routing
│   ├── api/
│   │   ├── client.js             # HTTP client (Fetch wrapper)
│   │   ├── auth.api.js           # Auth endpoints
│   │   ├── user.api.js           # User endpoints
│   │   ├── post.api.js           # Post endpoints
│   │   ├── group.api.js          # Group endpoints
│   │   ├── library.api.js        # Library endpoints
│   │   ├── mentorship.api.js     # Mentorship endpoints
│   │   ├── gamification.api.js   # Gamification endpoints
│   │   └── notification.api.js   # Notification endpoints
│   │
│   ├── services/
│   │   ├── auth.service.js       # Auth business logic
│   │   ├── user.service.js       # User business logic
│   │   ├── post.service.js       # Post business logic
│   │   ├── group.service.js      # Group business logic
│   │   ├── library.service.js    # Library business logic
│   │   ├── mentorship.service.js # Mentorship business logic
│   │   ├── gamification.service.js
│   │   ├── notification.service.js
│   │   └── theme.service.js      # Theme management
│   │
│   ├── components/               # Reusable UI components
│   │   ├── Component.js          # Base component class
│   │   ├── PostCard.js
│   │   ├── CommentItem.js
│   │   ├── UserCard.js
│   │   ├── Sidebar.js
│   │   ├── Navbar.js
│   │   ├── Feed.js
│   │   ├── TrendingWidget.js
│   │   ├── SuggestWidget.js
│   │   ├── GroupCard.js
│   │   ├── MaterialCard.js
│   │   ├── Badge.js
│   │   ├── Notification.js
│   │   ├── Modal.js
│   │   ├── Toast.js
│   │   ├── LoadingSpinner.js
│   │   ├── InfiniteScroll.js
│   │   └── ThemeToggle.js
│   │
│   ├── pages/                    # Page renderers
│   │   ├── AuthPage.js
│   │   ├── FeedPage.js
│   │   ├── ProfilePage.js
│   │   ├── PostDetailPage.js
│   │   ├── GroupsPage.js
│   │   ├── GroupDetailPage.js
│   │   ├── LibraryPage.js
│   │   ├── MentorshipPage.js
│   │   ├── NotificationsPage.js
│   │   ├── SettingsPage.js
│   │   └── AdminPage.js
│   │
│   ├── state/                    # State management
│   │   ├── Store.js              # Central store
│   │   ├── auth.store.js         # Auth state
│   │   ├── user.store.js         # User state
│   │   ├── post.store.js         # Post state
│   │   ├── ui.store.js           # UI state (theme, modals)
│   │   └── notification.store.js # Notification state
│   │
│   ├── utils/
│   │   ├── format.js             # Date, number formatting
│   │   ├── validation.js         # Form validation
│   │   ├── dom.js                # DOM utilities
│   │   ├── storage.js            # LocalStorage abstraction
│   │   ├── constants.js          # App constants
│   │   └── helpers.js            # Misc helpers
│   │
│   ├── hooks/                    # Custom hook-like functions
│   │   ├── useAuth.js
│   │   ├── useForm.js
│   │   ├── useInfiniteScroll.js
│   │   └── useTheme.js
│   │
│   └── constants/
│       ├── api.js                # API endpoints
│       ├── config.js             # App configuration
│       └── roles.js              # User role constants
│
├── public/
│   ├── favicon.ico
│   └── manifest.json
│
└── assets/
    ├── images/
    ├── icons/
    └── fonts/
```

## 4. Architecture Pattern

### 4.1 Component-Based Architecture

Each UI piece is a class extending a base `Component` class:

```javascript
// js/components/Component.js
export default class Component {
    constructor(containerId) {
        this.container = document.getElementById(containerId);
        this.state = {};
        this.init();
    }

    init() {}
    render() { this.container.innerHTML = this.template(); }
    template() { return ''; }
    afterRender() {}

    setState(newState) {
        Object.assign(this.state, newState);
        this.render();
    }

    destroy() {
        this.container.innerHTML = '';
    }
}
```

### 4.2 SPA Router

```javascript
// js/router.js
class Router {
    constructor() {
        this.routes = {};
        window.addEventListener('hashchange', () => this.resolve());
    }

    addRoute(path, handler) {
        this.routes[path] = handler;
        return this;
    }

    navigate(path) {
        window.location.hash = path;
    }

    resolve() {
        const hash = window.location.hash.slice(1) || '/feed';
        const handler = this.routes[hash];
        
        if (handler) {
            handler();
        } else {
            this.navigate('/404');
        }
    }

    start() {
        this.resolve();
        return this;
    }
}

export const router = new Router();
```

### 4.3 Store Pattern (State Management)

```javascript
// js/state/Store.js
class Store {
    constructor(initialState = {}) {
        this.state = initialState;
        this.listeners = [];
    }

    getState(key) {
        return key ? this.state[key] : this.state;
    }

    setState(updates) {
        Object.assign(this.state, updates);
        this.notify();
    }

    subscribe(listener) {
        this.listeners.push(listener);
        return () => {
            this.listeners = this.listeners.filter(l => l !== listener);
        };
    }

    notify() {
        this.listeners.forEach(listener => listener(this.state));
    }
}

export const authStore = new Store({
    user: null,
    token: null,
    isAuthenticated: false
});
```

## 5. Data Flow

```
User Action → Component → Service → API Client → Backend
                              ↓
                          Store update
                              ↓
                          Re-render
```

### 5.1 Example Flow (Creating a Post)

```
1. User types in form and clicks "Post"
2. PostCard component captures form submit
3. post.service.createPost(content) called
4. post.api.create(content) → POST /api/v1/posts
5. Backend returns { success: true, data: { post } }
6. post.store.setState({ posts: [post, ...] })
7. Store notifies Feed component
8. Feed re-renders with new post at top
```

## 6. State Management Strategy

| Store | Storage | Persistence |
|-------|---------|-------------|
| auth | Memory + localStorage | Token persisted |
| user | Memory | Session only |
| post | Memory | Session only |
| ui (theme) | Memory + localStorage | Theme persisted |
| notification | Memory | Session only |

## 7. HTTP Client

```javascript
// js/api/client.js
const API_BASE = 'http://localhost:8080/api/v1';

class ApiClient {
    constructor() {
        this.baseUrl = API_BASE;
    }

    getHeaders() {
        const headers = { 'Content-Type': 'application/json' };
        const token = localStorage.getItem('accessToken');
        if (token) headers['Authorization'] = `Bearer ${token}`;
        return headers;
    }

    async request(endpoint, options = {}) {
        const config = {
            headers: this.getHeaders(),
            ...options,
        };

        try {
            const response = await fetch(`${this.baseUrl}${endpoint}`, config);
            const data = await response.json();

            if (!response.ok) {
                if (response.status === 401) {
                    // Try refresh token
                    const refreshed = await this.refreshToken();
                    if (refreshed) {
                        config.headers['Authorization'] = `Bearer ${localStorage.getItem('accessToken')}`;
                        const retry = await fetch(`${this.baseUrl}${endpoint}`, config);
                        return retry.json();
                    }
                    // Redirect to login
                    window.location.hash = '/login';
                }
                throw new ApiError(data.message, response.status);
            }
            return data;
        } catch (error) {
            if (error instanceof ApiError) throw error;
            throw new ApiError('Network error', 0);
        }
    }

    async get(endpoint) {
        return this.request(endpoint, { method: 'GET' });
    }

    async post(endpoint, body) {
        return this.request(endpoint, {
            method: 'POST',
            body: JSON.stringify(body),
        });
    }

    async put(endpoint, body) {
        return this.request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(body),
        });
    }

    async delete(endpoint) {
        return this.request(endpoint, { method: 'DELETE' });
    }

    async refreshToken() {
        const refreshToken = localStorage.getItem('refreshToken');
        if (!refreshToken) return false;

        try {
            const response = await fetch(`${this.baseUrl}/auth/refresh`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ refreshToken }),
            });
            const data = await response.json();
            if (data.success) {
                localStorage.setItem('accessToken', data.data.accessToken);
                if (data.data.refreshToken) {
                    localStorage.setItem('refreshToken', data.data.refreshToken);
                }
                return true;
            }
            return false;
        } catch {
            return false;
        }
    }
}

export const apiClient = new ApiClient();
```

## 8. Responsive Layout

```
Desktop (>1024px):
┌──────────┬─────────────────────┬────────────┐
│ Sidebar  │      Feed           │  Widgets   │
│ 280px    │     flexible        │  320px     │
├──────────┴─────────────────────┴────────────┤
│                Footer                        │
└─────────────────────────────────────────────┘

Tablet (768-1024px):
┌──────────┬──────────────────────────────────┐
│ Sidebar  │            Feed                   │
│ 80px     │           flexible                │
│ (icons)  │                                   │
└──────────┴──────────────────────────────────┘

Mobile (<768px):
┌─────────────────────────────────────────────┐
│                    Top Bar                    │
├─────────────────────────────────────────────┤
│                    Feed                      │
│                   full width                 │
├─────────────────────────────────────────────┤
│              Bottom Navigation               │
└─────────────────────────────────────────────┘
```

## 9. Theming

CSS custom properties for dark/light mode:

```css
:root {
    --bg-primary: #ffffff;
    --bg-secondary: #f5f5f5;
    --text-primary: #1a1a1a;
    --text-secondary: #666666;
    --accent: #ff4d4d;  /* Pitaya red */
    --border: #e0e0e0;
}

[data-theme="dark"] {
    --bg-primary: #1a1a2e;
    --bg-secondary: #16213e;
    --text-primary: #e0e0e0;
    --text-secondary: #a0a0a0;
    --accent: #ff6b6b;
    --border: #2a2a3e;
}
```

## 10. Performance Considerations

1. **Lazy loading** of pages and components
2. **Debounced search** inputs
3. **Infinite scroll** with IntersectionObserver
4. **Minimal DOM manipulation** — batch updates
5. **CSS animations** over JS animations
6. **Image lazy loading** with loading="lazy"
7. **Throttled scroll events**
8. **Optimistic UI updates** for likes/comments
