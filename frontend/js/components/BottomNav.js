import Component from './Component.js';

export default class BottomNav extends Component {
  template() {
    const items = [
      { href: '#/feed', nav: '/feed', icon: '🏠', label: 'Feed' },
      { href: '#/explore', nav: '/explore', icon: '🔍', label: 'Explorar' },
      { href: '#/groups', nav: '/groups', icon: '👥', label: 'Grupos' },
      { href: '#/notifications', nav: '/notifications', icon: '🔔', label: 'Notif.' },
      { href: '#/profile', nav: '/profile', icon: '👤', label: 'Perfil' },
    ];

    return `
      ${items.map(item => `
        <a href="${item.href}" class="bottom-nav-item" data-nav="${item.nav}">
          <span class="nav-icon">${item.icon}</span>
          <span class="nav-label">${item.label}</span>
        </a>
      `).join('')}
    `;
  }
}
