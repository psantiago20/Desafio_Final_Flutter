import Component from './Component.js';
import { formatRelativeTime } from '../utils/format.js';
import { escapeHtml } from '../utils/helpers.js';

export default class CommentItem extends Component {
  template() {
    const comment = this.props.comment || {};
    const user = comment.author || comment.user || {};
    const avatar = user.avatarUrl || '';
    const initials = user.name ? this._getInitials(user.name) : '?';
    const time = comment.createdAt ? formatRelativeTime(comment.createdAt) : '';
    const liked = comment.liked || false;

    return `
      <div class="comment-item" data-comment-id="${comment.id || ''}">
        <div class="post-card-avatar">
          <a href="#/profile/${user.id || ''}" data-nav>
            ${avatar
              ? `<img src="${avatar}" alt="" class="avatar avatar-sm" loading="lazy" />`
              : `<div class="avatar avatar-sm avatar-placeholder" style="font-size:12px">${initials}</div>`
            }
          </a>
        </div>
        <div class="comment-content">
          <div style="background:var(--bg-tertiary);border-radius:var(--radius-md);padding:8px 12px">
            <a href="#/profile/${user.id || ''}" class="comment-author" data-nav>${escapeHtml(user.name || '')}</a>
            <span class="text-muted" style="font-size:12px">@${escapeHtml(user.username || '')}</span>
            <div class="comment-text">${this._renderContent(comment.content || '')}</div>
          </div>
          <div class="comment-actions">
            <span class="comment-action">${time}</span>
            <span class="comment-action" data-like-comment>${liked ? '❤️' : '🤍'} Curtir</span>
            <span class="comment-action" data-reply-comment>Responder</span>
          </div>
          ${comment.replies && comment.replies.length > 0 ? `
            <div style="margin-left:16px;margin-top:4px">
              ${comment.replies.map(reply => new CommentItem({
                props: { comment: reply, ...this.props }
              }).template()).join('')}
            </div>
          ` : ''}
        </div>
      </div>
    `;
  }

  events() {
    return {
      'click [data-like-comment]': '_handleLike',
      'click [data-reply-comment]': '_handleReply',
    };
  }

  _getInitials(name) {
    if (!name) return '?';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  _renderContent(text) {
    if (!text) return '';
    return escapeHtml(text)
      .replace(/#(\w+)/g, '<span class="hashtag">#$1</span>')
      .replace(/@(\w+)/g, '<span class="mention">@$1</span>');
  }

  _handleLike(e) {
    e.stopPropagation();
    this.props.onLikeComment?.(this.props.comment?.id);
  }

  _handleReply(e) {
    e.stopPropagation();
    this.props.onReply?.(this.props.comment?.id);
  }
}
