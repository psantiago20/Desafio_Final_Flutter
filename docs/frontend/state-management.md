# State Management

## 1. Objective

Document the client-side state management approach for the Pitaya frontend, using a custom Store pattern for predictable state handling without external libraries.

## 2. Store Architecture

```
┌─────────────────────────────┐
│         App State            │
├─────────────────────────────┤
│  auth.store.js               │
│  user.store.js               │
│  post.store.js               │
│  ui.store.js                 │
│  notification.store.js       │
└─────────────────────────────┘
         │         │
    ┌────┘         └────┐
    ▼                    ▼
┌──────────┐     ┌──────────────┐
│ Components│     │  Services    │
│ (read)    │     │  (write)     │
└──────────┘     └──────────────┘
```

## 3. Store Implementation

### 3.1 Base Store

```javascript
// js/state/Store.js
export default class Store {
    constructor(initialState = {}, options = {}) {
        this.state = { ...initialState };
        this.listeners = new Set();
        this.persistKey = options.persistKey || null;

        // Hydrate from storage if persistence configured
        if (this.persistKey) {
            this.hydrate();
        }

        // Freeze initial state in dev
        if (process.env.NODE_ENV === 'development') {
            this.initialState = Object.freeze({ ...initialState });
        }
    }

    get(key) {
        if (key) {
            return this.state[key];
        }
        return { ...this.state };
    }

    set(updates) {
        const prevState = { ...this.state };
        Object.assign(this.state, updates);

        // Persist if configured
        if (this.persistKey) {
            this.persist();
        }

        // Notify listeners
        this.listeners.forEach(listener => {
            try {
                listener(this.state, prevState);
            } catch (e) {
                console.error('Store listener error:', e);
            }
        });
    }

    reset() {
        this.set(this.initialState || {});
    }

    subscribe(listener) {
        this.listeners.add(listener);
        // Immediately notify with current state
        listener(this.state, {});
        // Return unsubscribe function
        return () => this.listeners.delete(listener);
    }

    persist() {
        try {
            localStorage.setItem(this.persistKey, JSON.stringify(this.state));
        } catch (e) {
            console.warn('Failed to persist state:', e);
        }
    }

    hydrate() {
        try {
            const stored = localStorage.getItem(this.persistKey);
            if (stored) {
                this.state = { ...this.state, ...JSON.parse(stored) };
            }
        } catch (e) {
            console.warn('Failed to hydrate state:', e);
        }
    }

    // Dev tool
    log() {
        console.group(`Store [${this.persistKey || 'anonymous'}]`);
        console.log('State:', this.state);
        console.log('Listeners:', this.listeners.size);
        console.groupEnd();
    }
}
```

### 3.2 Auth Store

```javascript
// js/state/auth.store.js
import Store from './Store.js';

const initialState = {
    user: null,
    accessToken: null,
    refreshToken: null,
    isAuthenticated: false,
    isLoading: false,
    error: null,
};

const authStore = new Store(initialState, { persistKey: 'pitaya_auth' });

// Derived getters
authStore.getUser = () => authStore.get('user');
authStore.isAuthenticated = () => authStore.get('isAuthenticated');
authStore.isAdmin = () => authStore.get('user')?.role === 'ADMIN';
authStore.getRole = () => authStore.get('user')?.role;

export default authStore;
```

### 3.3 Post Store

```javascript
// js/state/post.store.js
import Store from './Store.js';

const initialState = {
    posts: [],
    currentPost: null,
    trendingTopics: [],
    isLoading: false,
    pagination: {
        page: 0,
        size: 20,
        totalPages: 0,
        last: false,
    },
    filters: {
        sort: 'latest',
        hashtag: null,
    },
};

const postStore = new Store(initialState);

postStore.addPost = function(post) {
    const posts = [post, ...this.get('posts')];
    this.set({ posts });
};

postStore.removePost = function(postId) {
    const posts = this.get('posts').filter(p => p.id !== postId);
    this.set({ posts });
};

postStore.updatePost = function(postId, updates) {
    const posts = this.get('posts').map(p =>
        p.id === postId ? { ...p, ...updates } : p
    );
    this.set({ posts });
};

postStore.toggleLike = function(postId) {
    const posts = this.get('posts').map(p => {
        if (p.id === postId) {
            return {
                ...p,
                isLiked: !p.isLiked,
                likeCount: p.isLiked ? p.likeCount - 1 : p.likeCount + 1,
            };
        }
        return p;
    });
    this.set({ posts });
};

postStore.appendPosts = function(newPosts, pagination) {
    const existingIds = new Set(this.get('posts').map(p => p.id));
    const unique = newPosts.filter(p => !existingIds.has(p.id));
    this.set({
        posts: [...this.get('posts'), ...unique],
        pagination: { ...this.get('pagination'), ...pagination },
    });
};

export default postStore;
```

### 3.4 UI Store

```javascript
// js/state/ui.store.js
import Store from './Store.js';

const initialState = {
    theme: localStorage.getItem('pitaya_theme') || 'light',
    sidebarOpen: true,
    composerOpen: false,
    modal: null,
    toasts: [],
    activeTab: 'feed',
};

const uiStore = new Store(initialState);

uiStore.toggleTheme = function() {
    const theme = this.get('theme') === 'light' ? 'dark' : 'light';
    this.set({ theme });
    localStorage.setItem('pitaya_theme', theme);
    document.documentElement.setAttribute('data-theme', theme);
};

uiStore.showToast = function(message, type = 'info', duration = 3000) {
    const toast = { id: Date.now(), message, type };
    const toasts = [...this.get('toasts'), toast];
    this.set({ toasts });

    setTimeout(() => {
        const remaining = this.get('toasts').filter(t => t.id !== toast.id);
        this.set({ toasts: remaining });
    }, duration);
};

uiStore.openModal = function(component, props = {}) {
    this.set({ modal: { component, props } });
};

uiStore.closeModal = function() {
    this.set({ modal: null });
};

export default uiStore;
```

## 4. State Usage in Components

```javascript
// js/components/Sidebar.js
import Component from './Component.js';
import authStore from '../state/auth.store.js';
import uiStore from '../state/ui.store.js';

export default class Sidebar extends Component {
    mounted() {
        // Subscribe to auth changes
        this.subscribeTo(authStore, (state) => {
            if (state.user) {
                this.render();
            }
        });

        // Subscribe to UI changes
        this.subscribeTo(uiStore, (state) => {
            // Update active state
            this.render();
        });
    }

    template() {
        const user = authStore.getUser();
        const theme = uiStore.get('theme');

        return `
            <nav class="sidebar ${theme === 'dark' ? 'dark' : ''}">
                <div class="sidebar-header">
                    <h2>Pitaya</h2>
                    ${user ? `<span class="username">@${user.username}</span>` : ''}
                </div>
                <!-- ... -->
            </nav>
        `;
    }
}
```

## 5. State Flow Patterns

### 5.1 Form Submission

```javascript
async function handleLogin(email, password) {
    authStore.set({ isLoading: true, error: null });

    try {
        const response = await apiClient.post('/auth/login', { email, password });

        if (response.success) {
            authStore.set({
                user: response.data.user,
                accessToken: response.data.accessToken,
                refreshToken: response.data.refreshToken,
                isAuthenticated: true,
                isLoading: false,
            });
            router.navigate('/feed');
        }
    } catch (error) {
        authStore.set({
            isLoading: false,
            error: error.message,
        });
        uiStore.showToast(error.message, 'error');
    }
}
```

### 5.2 Optimistic Updates

```javascript
async function handleLike(postId) {
    // 1. Optimistic update
    postStore.toggleLike(postId);

    try {
        // 2. API call
        await postService.likePost(postId);
    } catch (error) {
        // 3. Rollback on failure
        postStore.toggleLike(postId);
        uiStore.showToast('Failed to like post', 'error');
    }
}
```

## 6. State Persistence Strategy

| Data | Store | Persist | Key |
|------|-------|---------|-----|
| Auth tokens | auth | Yes | `pitaya_auth` |
| Theme preference | ui | Yes | `pitaya_theme` |
| Feed posts | post | No | — |
| Current user data | user | No | — |
| Notifications | notification | No | — |
| Draft posts | — | Yes (session) | `pitaya_draft` |

## 7. Best Practices

1. **Single source of truth** — each data type belongs to one store
2. **Immutable updates** — always create new objects/arrays
3. **Minimal state** — derive what you can, store what you must
4. **Normalized data** — avoid deeply nested state
5. **Unsubscribe** — always clean up subscriptions in `destroy()`
6. **Error states** — track loading, error, and data states
7. **Optimistic updates** — update UI before API confirms
8. **Rollback** — revert state on API errors
