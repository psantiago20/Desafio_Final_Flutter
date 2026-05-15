# Routing Flow

## 1. Objective

Document the SPA routing system for the Pitaya frontend, including route configuration, navigation guards, lazy loading, and hash-based routing.

## 2. Router Implementation

```javascript
// js/router.js
class Router {
    constructor() {
        this.routes = new Map();
        this.guards = [];
        this.currentRoute = null;
        this.previousRoute = null;

        // Listen for hash changes
        window.addEventListener('hashchange', () => this.resolve());
        window.addEventListener('load', () => this.resolve());
    }

    addRoute(path, handler, options = {}) {
        this.routes.set(path, {
            path,
            handler,
            title: options.title || 'Pitaya',
            requiresAuth: options.requiresAuth || false,
            roles: options.roles || [],
            cleanup: options.cleanup || null,
        });
        return this;
    }

    addGuard(fn) {
        this.guards.push(fn);
        return this;
    }

    navigate(path) {
        window.location.hash = path;
    }

    getPath() {
        return window.location.hash.slice(1) || '/feed';
    }

    async resolve() {
        const path = this.getPath();
        const route = this.findRoute(path);

        if (!route) {
            this.render404();
            return;
        }

        // Run guards
        for (const guard of this.guards) {
            const result = await guard(route, path);
            if (result === false) return;
        }

        // Cleanup previous route
        if (this.currentRoute?.cleanup) {
            this.currentRoute.cleanup();
        }

        this.previousRoute = this.currentRoute;
        this.currentRoute = route;

        // Update document title
        document.title = route.title;

        // Clear main content
        const main = document.getElementById('main-content');
        main.innerHTML = '';

        // Load page component
        try {
            const page = await route.handler(path);
            if (page && page.mount) {
                page.mount(main);
            }
        } catch (error) {
            console.error('Route error:', error);
            this.renderError(error);
        }

        // Update active nav
        this.updateActiveNav(path);
    }

    findRoute(path) {
        // Exact match
        if (this.routes.has(path)) {
            return this.routes.get(path);
        }

        // Dynamic routes: /profile/:id
        for (const [pattern, route] of this.routes) {
            const regex = this.patternToRegex(pattern);
            const match = path.match(regex);
            if (match) {
                route.params = match.groups || {};
                return route;
            }
        }

        return null;
    }

    patternToRegex(pattern) {
        const regexStr = pattern
            .replace(/:\w+/g, '(?<$&>[^/]+)')
            .replace(/\$/g, '\\$')
            .replace(/\*/g, '.*');
        return new RegExp(`^${regexStr}$`);
    }

    render404() {
        const main = document.getElementById('main-content');
        main.innerHTML = `
            <div class="error-page">
                <h1>404</h1>
                <p>Página não encontrada</p>
                <a href="#/feed" class="btn btn-primary">Voltar ao Feed</a>
            </div>
        `;
    }

    renderError(error) {
        const main = document.getElementById('main-content');
        main.innerHTML = `
            <div class="error-page">
                <h1>Erro</h1>
                <p>${error.message || 'Ocorreu um erro inesperado'}</p>
                <button onclick="location.reload()" class="btn btn-primary">Recarregar</button>
            </div>
        `;
    }

    updateActiveNav(path) {
        document.querySelectorAll('.nav-link').forEach(link => {
            const href = link.getAttribute('href');
            link.classList.toggle('active', href === `#${path}`);
        });
    }

    start() {
        this.resolve();
        return this;
    }
}

export const router = new Router();
```

## 3. Route Configuration

```javascript
// js/app.js
import { router } from './router.js';
import authStore from './state/auth.store.js';

// Route definitions
const routes = [
    { path: '/login', page: 'AuthPage', title: 'Login - Pitaya', auth: false },
    { path: '/register', page: 'AuthPage', title: 'Registro - Pitaya', auth: false },
    { path: '/feed', page: 'FeedPage', title: 'Feed - Pitaya', auth: true },
    { path: '/explore', page: 'ExplorePage', title: 'Explorar - Pitaya', auth: true },
    { path: '/profile', page: 'ProfilePage', title: 'Perfil - Pitaya', auth: true },
    { path: '/profile/:id', page: 'ProfilePage', title: 'Perfil - Pitaya', auth: true },
    { path: '/profile/edit', page: 'ProfileEditPage', title: 'Editar Perfil - Pitaya', auth: true },
    { path: '/post/:id', page: 'PostDetailPage', title: 'Post - Pitaya', auth: true },
    { path: '/groups', page: 'GroupsPage', title: 'Grupos - Pitaya', auth: true },
    { path: '/groups/:id', page: 'GroupDetailPage', title: 'Grupo - Pitaya', auth: true },
    { path: '/library', page: 'LibraryPage', title: 'Biblioteca - Pitaya', auth: true },
    { path: '/mentorship', page: 'MentorshipPage', title: 'Mentorias - Pitaya', auth: true },
    { path: '/mentorship/:id', page: 'MentorshipSessionPage', title: 'Sessão - Pitaya', auth: true },
    { path: '/notifications', page: 'NotificationsPage', title: 'Notificações - Pitaya', auth: true },
    { path: '/settings', page: 'SettingsPage', title: 'Configurações - Pitaya', auth: true },
    { path: '/admin', page: 'AdminPage', title: 'Admin - Pitaya', auth: true, role: 'ADMIN' },
    { path: '/404', page: null, title: '404 - Pitaya', auth: false },
];

// Register routes
routes.forEach(route => {
    router.addRoute(
        route.path,
        async (path) => {
            const module = await import(`./pages/${route.page}.js`);
            const Page = module.default;
            const params = router.currentRoute?.params || {};
            return new Page({ path, params });
        },
        {
            title: route.title,
            requiresAuth: route.auth,
            roles: route.role ? [route.role] : [],
        }
    );
});
```

## 4. Navigation Guards

```javascript
// Authentication guard
router.addGuard(async (route, path) => {
    const isAuthenticated = authStore.isAuthenticated();

    // Route requires auth but user is not authenticated
    if (route.requiresAuth && !isAuthenticated) {
        router.navigate('/login');
        return false;
    }

    // User is authenticated but trying to access login/register
    if (!route.requiresAuth && isAuthenticated && ['/login', '/register'].includes(path)) {
        router.navigate('/feed');
        return false;
    }

    // Role check
    if (route.roles.length > 0) {
        const userRole = authStore.getRole();
        if (!route.roles.includes(userRole)) {
            router.navigate('/feed');
            uiStore.showToast('Acesso não autorizado', 'error');
            return false;
        }
    }

    return true;
});

// Profile not complete guard
router.addGuard(async (route, path) => {
    if (route.requiresAuth && path !== '/profile/edit' && path !== '/login' && path !== '/register') {
        const user = authStore.getUser();
        if (user && !user.profileComplete) {
            router.navigate('/profile/edit');
            uiStore.showToast('Complete seu perfil para continuar', 'info');
            return false;
        }
    }
    return true;
});
```

## 5. Route Table

| Path | Page | Auth | Roles | Description |
|------|------|------|-------|-------------|
| `/login` | AuthPage | No | — | Login form |
| `/register` | AuthPage | No | — | Registration form |
| `/feed` | FeedPage | Yes | ALL | Main timeline |
| `/explore` | ExplorePage | Yes | ALL | Discover content |
| `/profile` | ProfilePage | Yes | ALL | Own profile |
| `/profile/:id` | ProfilePage | Yes | ALL | User profile |
| `/profile/edit` | ProfileEditPage | Yes | ALL | Edit profile |
| `/post/:id` | PostDetailPage | Yes | ALL | Post detail |
| `/groups` | GroupsPage | Yes | ALL | Group list |
| `/groups/:id` | GroupDetailPage | Yes | ALL | Group detail |
| `/library` | LibraryPage | Yes | ALL | Material library |
| `/mentorship` | MentorshipPage | Yes | ALL | Mentorships |
| `/mentorship/:id` | MentorshipSessionPage | Yes | ALL | Session detail |
| `/notifications` | NotificationsPage | Yes | ALL | Notifications |
| `/settings` | SettingsPage | Yes | ALL | User settings |
| `/admin` | AdminPage | Yes | ADMIN | Admin panel |

## 6. Lazy Loading Strategy

```javascript
// Dynamic imports for code splitting
const pages = {
    FeedPage: () => import('./pages/FeedPage.js'),
    ProfilePage: () => import('./pages/ProfilePage.js'),
    GroupsPage: () => import('./pages/GroupsPage.js'),
    // ...
};

router.addRoute('/feed', async () => {
    const module = await pages.FeedPage();
    return new module.default();
});
```

## 7. Navigation Flow

```
User clicks link
       │
       ▼
router.navigate('/profile/abc123')
       │
       ▼
Hash changes to #/profile/abc123
       │
       ▼
hashchange event fires
       │
       ▼
router.resolve()
       │
       ▼
Find matching route (/profile/:id)
       │
       ▼
Run guards (auth, role, profile check)
       │
       ▼
Cleanup previous page
       │
       ▼
Load page module (lazy)
       │
       ▼
Mount page to #main-content
       │
       ▼
Update active nav
```

## 8. Error Handling

```javascript
// Global routing error handler
window.addEventListener('unhandledrejection', (event) => {
    if (event.reason?.isRoutingError) {
        router.renderError(event.reason);
    }
});

// 404 fallback
router.addRoute('*', async () => {
    router.render404();
}, { title: '404 - Pitaya' });
```
