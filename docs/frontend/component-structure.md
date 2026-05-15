# Component Structure

## 1. Objective

Document the component system of the Pitaya frontend, including the base component class, lifecycle, component hierarchy, and rendering patterns.

## 2. Base Component

```javascript
// js/components/Component.js
export default class Component {
    constructor(options = {}) {
        this.id = options.id || `comp-${Date.now()}`;
        this.container = options.container
            ? (typeof options.container === 'string'
                ? document.querySelector(options.container)
                : options.container)
            : null;
        this.state = options.initialState || {};
        this.props = options.props || {};
        this.subscriptions = [];
        this.isMounted = false;
    }

    // Lifecycle hooks
    beforeMount() {}
    mounted() {}
    beforeUpdate() {}
    updated() {}
    beforeDestroy() {}
    destroyed() {}

    // Template — override in subclass
    template() {
        return '';
    }

    // Events — override in subclass, returns object
    events() {
        return {};
    }

    // Render
    render() {
        if (!this.container) return;
        this.beforeUpdate();
        this.container.innerHTML = this.template();
        this.bindEvents();
        this.updated();
    }

    // Mount to DOM
    mount(container) {
        if (container) this.container = container;
        if (!this.container) throw new Error('No container specified');
        this.beforeMount();
        this.container.innerHTML = this.template();
        this.bindEvents();
        this.mounted();
        this.isMounted = true;
    }

    // Bind events from events() hash
    bindEvents() {
        const events = this.events();
        Object.entries(events).forEach(([key, handler]) => {
            const [event, selector] = key.split(' ');
            const elements = this.container.querySelectorAll(selector);
            elements.forEach(el => {
                el.addEventListener(event, handler.bind(this));
            });
        });
    }

    // State management
    setState(newState) {
        this.beforeUpdate();
        Object.assign(this.state, newState);
        this.render();
    }

    // Subscribe to store
    subscribeTo(store, callback) {
        const unsubscribe = store.subscribe((state) => {
            callback.call(this, state);
        });
        this.subscriptions.push(unsubscribe);
    }

    // Cleanup
    destroy() {
        this.beforeDestroy();
        this.subscriptions.forEach(fn => fn());
        this.subscriptions = [];
        this.container.innerHTML = '';
        this.destroyed();
        this.isMounted = false;
    }
}
```

## 3. Component Hierarchy

```
App
├── Navbar
│   ├── Logo
│   ├── SearchBar
│   ├── ThemeToggle
│   └── UserMenu
│       └── Avatar
│
├── Sidebar
│   ├── NavItem (Feed)
│   ├── NavItem (Explore)
│   ├── NavItem (Groups)
│   ├── NavItem (Library)
│   ├── NavItem (Mentorship)
│   ├── NavItem (Notifications)
│   └── NavItem (Profile)
│
├── Main Content (varies by route)
│   ├── FeedPage
│   │   ├── PostComposer
│   │   ├── Feed
│   │   │   ├── PostCard (multiple)
│   │   │   │   ├── PostHeader
│   │   │   │   ├── PostContent
│   │   │   │   ├── PostActions
│   │   │   │   │   ├── LikeButton
│   │   │   │   │   ├── CommentButton
│   │   │   │   │   └── RepostButton
│   │   │   │   └── PostComments
│   │   │   │       ├── CommentItem (multiple)
│   │   │   │       └── CommentForm
│   │   │   └── InfiniteScroll
│   │   └── LoadingSpinner
│   │
│   ├── ProfilePage
│   │   ├── ProfileHeader
│   │   ├── ProfileTabs
│   │   └── ProfileFeed
│   │
│   ├── GroupsPage
│   │   ├── GroupList
│   │   │   └── GroupCard (multiple)
│   │   └── CreateGroupModal
│   │
│   └── ...
│
├── RightSidebar
│   ├── TrendingWidget
│   ├── SuggestWidget
│   └── BadgeWidget
│
├── Modal
│   ├── ModalOverlay
│   └── ModalContent
│
└── Toast
    └── ToastMessage (multiple)
```

## 4. Example Components

### 4.1 PostCard Component

```javascript
// js/components/PostCard.js
import Component from './Component.js';
import { postService } from '../services/post.service.js';
import { formatRelativeTime } from '../utils/format.js';

export default class PostCard extends Component {
    constructor(options) {
        super(options);
        this.post = options.props.post;
    }

    template() {
        const { post } = this;
        return `
            <article class="post-card" data-post-id="${post.id}">
                <div class="post-header">
                    <img class="post-avatar" src="${post.author.avatar || 'assets/images/default-avatar.png'}"
                         alt="${post.author.fullName}" loading="lazy">
                    <div class="post-author-info">
                        <a href="#/profile/${post.author.id}" class="post-author-name">
                            ${post.author.fullName}
                        </a>
                        <span class="post-username">@${post.author.username}</span>
                        <span class="post-time">${formatRelativeTime(post.createdAt)}</span>
                    </div>
                </div>

                <div class="post-content">
                    <p>${this.renderHashtags(post.content)}</p>
                    ${post.image ? `<img src="${post.image}" alt="Post image" loading="lazy">` : ''}
                </div>

                <div class="post-actions">
                    <button class="action-btn like-btn ${post.isLiked ? 'liked' : ''}"
                            data-action="like">
                        <span class="icon">${post.isLiked ? '❤️' : '🤍'}</span>
                        <span class="count">${post.likeCount}</span>
                    </button>

                    <button class="action-btn comment-btn" data-action="comment">
                        <span class="icon">💬</span>
                        <span class="count">${post.commentCount}</span>
                    </button>

                    <button class="action-btn repost-btn ${post.isReposted ? 'reposted' : ''}"
                            data-action="repost">
                        <span class="icon">🔁</span>
                        <span class="count">${post.repostCount}</span>
                    </button>

                    <button class="action-btn share-btn" data-action="share">
                        <span class="icon">📤</span>
                    </button>
                </div>
            </article>
        `;
    }

    renderHashtags(content) {
        return content.replace(/#(\w+)/g, '<span class="hashtag">#$1</span>');
    }

    events() {
        return {
            'click .like-btn': this.handleLike,
            'click .comment-btn': this.handleComment,
            'click .repost-btn': this.handleRepost,
            'click .share-btn': this.handleShare,
        };
    }

    async handleLike(e) {
        e.preventDefault();
        const btn = e.currentTarget;
        btn.classList.toggle('liked');
        const isLiked = btn.classList.contains('liked');
        const countEl = btn.querySelector('.count');
        countEl.textContent = parseInt(countEl.textContent) + (isLiked ? 1 : -1);

        try {
            if (isLiked) {
                await postService.likePost(this.post.id);
            } else {
                await postService.unlikePost(this.post.id);
            }
        } catch (error) {
            // Rollback on error
            btn.classList.toggle('liked');
            countEl.textContent = parseInt(countEl.textContent) + (isLiked ? -1 : 1);
        }
    }

    handleComment() {
        window.dispatchEvent(new CustomEvent('open-comment', {
            detail: { postId: this.post.id }
        }));
    }

    async handleRepost() {
        try {
            const result = await postService.repost(this.post.id);
            if (result.success) {
                this.post.repostCount++;
                this.render();
            }
        } catch (error) {
            console.error('Repost failed', error);
        }
    }

    handleShare() {
        if (navigator.share) {
            navigator.share({
                title: this.post.content.slice(0, 100),
                url: `${window.location.origin}/#/post/${this.post.id}`,
            });
        } else {
            navigator.clipboard.writeText(
                `${window.location.origin}/#/post/${this.post.id}`
            );
        }
    }
}
```

### 4.2 Sidebar Component

```javascript
// js/components/Sidebar.js
import Component from './Component.js';

export default class Sidebar extends Component {
    template() {
        const navItems = [
            { icon: '🏠', label: 'Feed', path: '/feed' },
            { icon: '🔍', label: 'Explorar', path: '/explore' },
            { icon: '👥', label: 'Grupos', path: '/groups' },
            { icon: '📚', label: 'Biblioteca', path: '/library' },
            { icon: '🎓', label: 'Mentorias', path: '/mentorship' },
            { icon: '🔔', label: 'Notificações', path: '/notifications' },
            { icon: '👤', label: 'Perfil', path: '/profile' },
            { icon: '⚙️', label: 'Configurações', path: '/settings' },
        ];

        const currentPath = window.location.hash.slice(1);

        return `
            <nav class="sidebar">
                <div class="sidebar-logo">
                    <h1 class="logo">🍓 Pitaya</h1>
                </div>

                <ul class="sidebar-nav">
                    ${navItems.map(item => `
                        <li class="nav-item ${currentPath === item.path ? 'active' : ''}">
                            <a href="#${item.path}" class="nav-link">
                                <span class="nav-icon">${item.icon}</span>
                                <span class="nav-label">${item.label}</span>
                            </a>
                        </li>
                    `).join('')}
                </ul>

                <div class="sidebar-footer">
                    <button class="post-btn" id="newPostBtn">
                        <span class="icon">✏️</span>
                        <span class="label">Postar</span>
                    </button>
                </div>
            </nav>
        `;
    }

    events() {
        return {
            'click #newPostBtn': this.openNewPost,
        };
    }

    openNewPost() {
        window.dispatchEvent(new CustomEvent('open-composer'));
    }
}
```

## 5. Component Conventions

| Convention | Rule |
|-----------|------|
| File naming | PascalCase, e.g., `PostCard.js` |
| Class naming | PascalCase matching filename |
| CSS classes | kebab-case, e.g., `post-card` |
| Data attributes | `data-*` for JS hooks |
| Events | `handle{Action}` pattern |
| Template literals | Backticks for HTML strings |
| State | Immutable updates via `setState` |

## 6. Styling Convention

```css
/* Component: PostCard */
.post-card {
    background: var(--bg-primary);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 16px;
    margin-bottom: 12px;
    transition: box-shadow 0.2s ease;
}

.post-card:hover {
    box-shadow: 0 2px 12px rgba(0,0,0,0.1);
}

.post-card .post-header {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 12px;
}

.post-card .post-avatar {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    object-fit: cover;
}

.post-card .post-content {
    margin-bottom: 12px;
    line-height: 1.5;
}

.post-card .post-content .hashtag {
    color: var(--accent);
    cursor: pointer;
}

.post-card .post-actions {
    display: flex;
    gap: 24px;
    border-top: 1px solid var(--border);
    padding-top: 12px;
}

.post-card .action-btn {
    display: flex;
    align-items: center;
    gap: 6px;
    background: none;
    border: none;
    cursor: pointer;
    color: var(--text-secondary);
    font-size: 14px;
    transition: color 0.2s;
}

.post-card .action-btn:hover {
    color: var(--accent);
}

.post-card .action-btn.liked {
    color: #e0245e;
}
```

## 7. Component Communication

```
Parent → Child: Props (options.props)
Child → Parent: Custom Events (window.dispatchEvent)
Child → Store: Store.setState()
Store → Child: Store.subscribe()
```
