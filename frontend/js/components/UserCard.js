import Component from './Component.js';
import { escapeHtml } from '../utils/helpers.js';

export default class UserCard extends Component {
  template() {
    const user = this.props.user || {};
    const avatar = user.avatarUrl || '';
    const initials = user.name ? this._getInitials(user.name) : '?';
    const isFollowing = user.isFollowing || false;
    const showFollowBtn = this.props.showFollowBtn !== false;
    const isLoading = this.state?.loadingFollow || false;

    return `
      <div class="user-card" data-user-id="${user.id || ''}">
        <a href="#/profile/${user.id || ''}" data-nav>
          ${avatar
            ? `<img src="${avatar}" alt="" class="avatar avatar-sm" loading="lazy" />`
            : `<div class="avatar avatar-sm avatar-placeholder" style="font-size:12px">${initials}</div>`
          }
        </a>
        <div class="user-card-info">
          <a href="#/profile/${user.id || ''}" data-nav>
            <div class="user-card-name">${escapeHtml(user.name || '')}</div>
            <div class="user-card-username">@${escapeHtml(user.username || '')}</div>
          </a>
        </div>
        ${showFollowBtn ? `
          <button class="btn ${isFollowing ? 'btn-outline' : 'btn-primary'} btn-sm" data-follow-user ${isLoading ? 'disabled' : ''}>
            ${isLoading ? '...' : (isFollowing ? 'Seguindo' : 'Seguir')}
          </button>
        ` : ''}
      </div>
    `;
  }

  events() {
    return {
      'click [data-follow-user]': '_handleFollow',
    };
  }

  _getInitials(name) {
    if (!name) return '?';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  _handleFollow(e) {
    e.preventDefault();
    const userId = this.props.user?.id;
    if (!userId) return;
    this.props.onFollow?.(userId);
  }
}
