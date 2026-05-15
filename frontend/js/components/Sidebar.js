import Component from './Component.js';
import authStore from '../state/auth.store.js';
import { hasPermission } from '../constants/roles.js';

export default class Sidebar extends Component {
  mounted() {
    this.unsub = this.subscribeTo(authStore, () => this.render());
  }

  template() {
    const user = authStore.get('user');
    const role = user?.role || 'USER';
    const isAdmin = hasPermission(role, 'VIEW_ADMIN');

    const links = [
      { href: '#/feed', nav: '/feed', icon: '🏠', label: 'Feed' },
      { href: '#/explore', nav: '/explore', icon: '🔍', label: 'Explorar' },
      { href: '#/groups', nav: '/groups', icon: '👥', label: 'Grupos' },
      { href: '#/library', nav: '/library', icon: '📚', label: 'Biblioteca' },
      { href: '#/mentorship', nav: '/mentorship', icon: '🎓', label: 'Mentorias' },
      { href: '#/notifications', nav: '/notifications', icon: '🔔', label: 'Notificações' },
      { href: '#/profile', nav: '/profile', icon: '👤', label: 'Perfil' },
      { href: '#/settings', nav: '/settings', icon: '⚙️', label: 'Configurações' },
    ];

    if (isAdmin) {
      links.push({ href: '#/admin', nav: '/admin', icon: '🛡️', label: 'Admin' });
    }

    return `
      <div class="sidebar-inner">
        <nav class="sidebar-nav">
          ${links.map(link => `
            <a href="${link.href}" class="sidebar-nav-item" data-nav="${link.nav}">
              <span class="nav-icon">${link.icon}</span>
              <span class="nav-label">${link.label}</span>
            </a>
          `).join('')}
        </nav>

        <button class="btn btn-primary sidebar-post-btn" data-post-btn>
          <span class="nav-icon">✏️</span>
          <span class="btn-label">Postar</span>
        </button>
      </div>
    `;
  }

  events() {
    return {
      'click [data-post-btn]': '_handlePostClick',
    };
  }

  _handlePostClick() {
    window.location.hash = '#/feed';
    setTimeout(() => {
      const composer = document.querySelector('.post-composer-textarea');
      if (composer) composer.focus();
    }, 100);
  }

  destroy() {
    if (this.unsub) this.unsub();
    super.destroy();
  }
}
