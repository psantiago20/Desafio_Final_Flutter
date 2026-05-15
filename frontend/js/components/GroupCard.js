import Component from './Component.js';
import { escapeHtml } from '../utils/helpers.js';

export default class GroupCard extends Component {
  template() {
    const group = this.props.group || {};
    const avatar = group.avatarUrl || group.imageUrl || '';
    const initials = group.name ? this._getInitials(group.name) : 'G';
    const isMember = group.isMember || false;
    const isLoading = this.state?.loadingJoin || false;

    return `
      <div class="group-card" data-group-id="${group.id || ''}">
        ${avatar
          ? `<img src="${avatar}" alt="" class="group-card-avatar" loading="lazy" />`
          : `<div class="group-card-avatar avatar-placeholder" style="border-radius:12px;font-size:20px">${initials}</div>`
        }
        <div class="group-card-info">
          <a href="#/groups/${group.id}" class="group-card-name">${escapeHtml(group.name || '')}</a>
          <div class="group-card-meta">
            ${group.memberCount || 0} membros
            ${group.category ? `· ${escapeHtml(group.category)}` : ''}
          </div>
          <div class="group-card-desc">${escapeHtml(group.description || '')}</div>
        </div>
        <div style="flex-shrink:0">
          <button class="btn ${isMember ? 'btn-outline' : 'btn-primary'} btn-sm" data-group-action ${isLoading ? 'disabled' : ''}>
            ${isLoading ? '...' : (isMember ? 'Sair' : 'Entrar')}
          </button>
        </div>
      </div>
    `;
  }

  events() {
    return {
      'click [data-group-action]': '_handleAction',
    };
  }

  _getInitials(name) {
    if (!name) return 'G';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  _handleAction(e) {
    e.stopPropagation();
    const groupId = this.props.group?.id;
    if (!groupId) return;
    this.props.onAction?.(groupId);
  }
}
