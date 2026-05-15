import { setCurrentRoute } from './state/ui.store.js';

class Router {
  constructor() {
    this.routes = [];
    this.guards = [];
    this.currentRoute = null;
    this.previousRoute = null;
    this._cleanupFns = [];
    this._onHashChange = this._onHashChange.bind(this);
  }

  addRoute(pattern, component, options = {}) {
    const paramNames = [];
    const regexStr = pattern.replace(/:([a-zA-Z_]+)/g, (_, name) => {
      paramNames.push(name);
      return '([^/]+)';
    });
    const regex = new RegExp(`^${regexStr}$`);
    this.routes.push({ pattern, regex, paramNames, component, options });
    return this;
  }

  addGuard(fn) {
    this.guards.push(fn);
    return this;
  }

  start() {
    window.addEventListener('hashchange', this._onHashChange);
    this._onHashChange();
  }

  stop() {
    window.removeEventListener('hashchange', this._onHashChange);
  }

  navigate(hash) {
    window.location.hash = hash;
  }

  goBack() {
    if (this.previousRoute) {
      window.location.hash = this.previousRoute.hash;
    } else {
      window.location.hash = '#/feed';
    }
  }

  getCurrentPath() {
    return window.location.hash.slice(1) || '/login';
  }

  async _onHashChange() {
    const path = this.getCurrentPath();

    let match = null;
    let route = null;
    let params = {};

    for (const r of this.routes) {
      const m = path.match(r.regex);
      if (m) {
        match = m;
        route = r;
        params = {};
        r.paramNames.forEach((name, i) => {
          params[name] = decodeURIComponent(m[i + 1]);
        });
        break;
      }
    }

    if (!route) {
      route = this.routes.find(r => r.pattern === '/404');
      if (!route) {
        console.error('No 404 route registered');
        return;
      }
    }

    for (const guard of this.guards) {
      const result = await guard(path, route, params);
      if (result === false) return;
    }

    if (this._cleanupFns.length > 0) {
      for (const fn of this._cleanupFns) {
        try { fn(); } catch (e) { console.error('Cleanup error:', e); }
      }
      this._cleanupFns = [];
    }

    this.previousRoute = this.currentRoute;
    this.currentRoute = { path, route, params };

    setCurrentRoute(path);

    const mainContent = document.getElementById('main-content');
    if (mainContent) {
      mainContent.innerHTML = '';
    }

    if (typeof route.component === 'function') {
      const instance = new route.component({ props: params });
      if (mainContent) {
        instance.mount(mainContent);
      }
      if (instance.destroy) {
        this._cleanupFns.push(() => instance.destroy());
      }
    } else if (typeof route.component === 'string') {
      if (mainContent) {
        mainContent.innerHTML = route.component;
      }
    }

    this.updateActiveNav();
  }

  updateActiveNav() {
    const path = this.getCurrentPath();
    document.querySelectorAll('[data-nav]').forEach(el => {
      const navPath = el.dataset.nav;
      if (navPath === '/') {
        el.classList.toggle('active', path === '/' || path === '/feed');
      } else {
        el.classList.toggle('active', path.startsWith(navPath));
      }
    });
  }

  addCleanup(fn) {
    this._cleanupFns.push(fn);
  }
}

const router = new Router();
export default router;
