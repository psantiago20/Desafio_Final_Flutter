import Component from './Component.js';
import { toggleTheme } from '../services/theme.service.js';

export default class ThemeToggle extends Component {
  template() {
    const current = document.documentElement.getAttribute('data-theme') || 'light';
    const icon = current === 'dark' ? '☀️' : '🌙';
    const label = current === 'dark' ? 'Modo Claro' : 'Modo Escuro';
    return `
      <button class="nav-icon-btn theme-toggle" data-nav="theme" title="${label}" aria-label="${label}">
        <span class="theme-icon">${icon}</span>
      </button>
    `;
  }

  events() {
    return {
      'click .theme-toggle': '_handleToggle',
    };
  }

  _handleToggle() {
    const next = toggleTheme();
    const iconEl = this.container?.querySelector('.theme-icon');
    if (iconEl) {
      iconEl.textContent = next === 'dark' ? '☀️' : '🌙';
    }
    const btn = this.container?.querySelector('.theme-toggle');
    if (btn) {
      const label = next === 'dark' ? 'Modo Claro' : 'Modo Escuro';
      btn.title = label;
      btn.setAttribute('aria-label', label);
    }
  }
}
