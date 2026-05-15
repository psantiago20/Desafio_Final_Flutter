import Component from './Component.js';
import { formatRelativeTime } from '../utils/format.js';
import { escapeHtml } from '../utils/helpers.js';

export default class PostCard extends Component {
  template() {
    const post = this.props.post || {};
    const user = post.author || post.user || {};
    const avatar = user.avatarUrl || '';
    const initials = user.name ? this._getInitials(user.name) : '?';
    const time = post.createdAt ? formatRelativeTime(post.createdAt) : '';
    const liked = post.liked || false;
    const likeCount = post.likeCount || 0;
    const commentCount = post.commentCount || 0;
    const repostCount = post.repostCount || 0;
    const content = this._renderContent(post.content || '');
    const imageUrl = post.imageUrl || (post.images && post.images[0]);
    const hasImage = !!imageUrl;
    const repostedBy = post.repostedBy || null;
    const isRepost = !!post.repostOf;

    return `
      <article class="post-card" data-post-id="${post.id || ''}">
        <div class="post-card-avatar">
          <a href="#/profile/${user.id || ''}" data-nav>
            ${avatar
              ? `<img src="${avatar}" alt="" class="avatar" loading="lazy" />`
              : `<div class="avatar avatar-placeholder">${initials}</div>`
            }
          </a>
        </div>
        <div class="post-card-body">
          ${isRepost && repostedBy ? `<div class="post-card-repost-indicator">🔁 ${escapeHtml(repostedBy.name || '')} repostou</div>` : ''}
          <div class="post-card-header">
            <a href="#/profile/${user.id || ''}" class="post-card-name" data-nav>${escapeHtml(user.name || '')}</a>
            <span class="post-card-username">@${escapeHtml(user.username || '')}</span>
            <span class="post-card-dot">·</span>
            <span class="post-card-time">${time}</span>
          </div>
          <div class="post-card-content">${content}</div>
          ${hasImage ? `
            <div class="post-card-images single">
              <img src="${imageUrl}" alt="Imagem do post" loading="lazy" />
            </div>
          ` : ''}
          <div class="post-card-actions">
            <button class="post-action-btn ${liked ? 'liked' : ''}" data-like data-post-id="${post.id}">
              <span>${liked ? '❤️' : '🤍'}</span>
              ${likeCount > 0 ? `<span>${likeCount}</span>` : ''}
            </button>
            <button class="post-action-btn" data-comment data-post-id="${post.id}">
              <span>💬</span>
              ${commentCount > 0 ? `<span>${commentCount}</span>` : ''}
            </button>
            <button class="post-action-btn" data-repost data-post-id="${post.id}">
              <span>🔁</span>
              ${repostCount > 0 ? `<span>${repostCount}</span>` : ''}
            </button>
            <button class="post-action-btn" data-share data-post-id="${post.id}">
              <span>📤</span>
            </button>
          </div>
        </div>
      </article>
    `;
  }

  events() {
    return {
      'click [data-like]': '_handleLike',
      'click [data-comment]': '_handleComment',
      'click [data-repost]': '_handleRepost',
      'click [data-share]': '_handleShare',
      'click .hashtag': '_handleHashtagClick',
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
    const escaped = escapeHtml(text);
    return escaped
      .replace(/#(\w+)/g, '<a class="hashtag" data-hashtag="$1">#$1</a>')
      .replace(/@(\w+)/g, '<a class="mention" href="#/profile/$1">@$1</a>');
  }

  _handleLike(e) {
    e.stopPropagation();
    const btn = e.currentTarget;
    const postId = btn.dataset.postId;
    if (!postId) return;
    this.props.onLike?.(postId);
  }

  _handleComment(e) {
    e.stopPropagation();
    const postId = e.currentTarget.dataset.postId;
    if (!postId) return;
    this.props.onComment?.(postId);
  }

  _handleRepost(e) {
    e.stopPropagation();
    const postId = e.currentTarget.dataset.postId;
    if (!postId) return;
    this.props.onRepost?.(postId);
  }

  _handleShare(e) {
    e.stopPropagation();
    const postId = e.currentTarget.dataset.postId;
    if (!postId) return;
    this.props.onShare?.(postId);
  }

  _handleHashtagClick(e) {
    e.stopPropagation();
    const hashtag = e.target.dataset.hashtag;
    if (hashtag) {
      window.location.hash = `#/explore?tag=${hashtag}`;
    }
  }
}
