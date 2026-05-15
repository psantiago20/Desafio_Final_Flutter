import Component from './Component.js';
import authStore from '../state/auth.store.js';
import { logout } from '../services/auth.service.js';
import ThemeToggle from './ThemeToggle.js';
import { APP_NAME } from '../constants/config.js';

export default class Navbar extends Component {
  mounted() {
    this.unsub = this.subscribeTo(authStore, () => this.render());
    this._mountThemeToggle();
  }

  _mountThemeToggle() {
    const el = this.container?.querySelector('#theme-toggle-target');
    if (el) {
      this._themeToggle = new ThemeToggle({ container: el });
      this._themeToggle.mount(el);
    }
  }

  template() {
    const user = authStore.get('user');
    const unread = authStore.get('unreadCount') || 0;
    const avatar = user?.avatarUrl || '';
    const initials = user?.name ? this._getInitials(user.name) : '?';

    return `
      <div class="nav-inner">
        <div class="flex items-center gap-md">
          <button class="nav-icon-btn mobile-menu-btn" data-nav="menu" aria-label="Menu">
            <span>☰</span>
          </button>
          <a href="#/feed" class="navbar-logo" data-nav="/feed">${APP_NAME}</a>
        </div>

        <div class="navbar-search">
          <span class="search-icon">🔍</span>
          <input type="search" placeholder="Buscar no Pitaya..." data-search-input />
        </div>

        <div class="navbar-actions">
          <div id="theme-toggle-target"></div>

          <a href="#/notifications" class="nav-icon-btn" data-nav="/notifications" title="Notificações">
            <span>🔔</span>
            ${unread > 0 ? `<span class="badge">${unread > 9 ? '9+' : unread}</span>` : ''}
          </a>

          <div class="user-dropdown" data-dropdown>
            <button class="nav-icon-btn user-dropdown-trigger" data-dropdown-trigger title="Perfil">
              ${avatar
                ? `<img src="${avatar}" alt="Avatar" class="avatar avatar-sm" />`
                : `<div class="avatar avatar-sm avatar-placeholder">${initials}</div>`
              }
            </button>
            <div class="dropdown-menu" data-dropdown-menu>
              <a href="#/profile" class="dropdown-item" data-nav="/profile">Meu Perfil</a>
              <a href="#/settings" class="dropdown-item" data-nav="/settings">Configurações</a>
              <hr class="dropdown-divider" />
              <button class="dropdown-item" data-logout>Sair</button>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  events() {
    return {
      'click [data-dropdown-trigger]': '_toggleDropdown',
      'click [data-logout]': '_handleLogout',
      'click [data-nav="menu"]': '_toggleMobileMenu',
    };
  }

  _getInitials(name) {
    if (!name) return '?';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  _toggleDropdown(e) {
    e.stopPropagation();
    const menu = this.container?.querySelector('[data-dropdown-menu]');
    if (menu) {
      menu.classList.toggle('visible');
      if (menu.classList.contains('visible')) {
        const close = (ev) => {
          if (!menu.contains(ev.target) && ev.target !== e.target) {
            menu.classList.remove('visible');
            document.removeEventListener('click', close);
          }
        };
        setTimeout(() => document.addEventListener('click', close), 0);
      }
    }
  }

  _handleLogout() {
    logout();
  }

  _toggleMobileMenu() {
    document.body.classList.toggle('mobile-menu-open');
  }

  destroy() {
    if (this.unsub) this.unsub();
    super.destroy();
  }
}
