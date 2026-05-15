import { Link, useNavigate } from 'react-router-dom';
import { formatRelativeTime } from '../utils/format';
import { escapeHtml, getInitials } from '../utils/helpers';

export default function PostCard({ post, onLike, onComment, onRepost, onShare }) {
  const navigate = useNavigate();
  const user = post?.author || post?.user || {};
  const avatar = user.avatarUrl || '';
  const initials = getInitials(user.name);
  const time = post?.createdAt ? formatRelativeTime(post.createdAt) : '';
  const liked = post?.liked || false;
  const likeCount = post?.likeCount || 0;
  const commentCount = post?.commentCount || 0;
  const repostCount = post?.repostCount || 0;
  const imageUrl = post?.imageUrl || (post?.images && post.images[0]);
  const repostedBy = post?.repostedBy || null;
  const isRepost = !!post?.repostOf;

  function renderContent(text) {
    if (!text) return '';
    const escaped = escapeHtml(text);
    return escaped
      .replace(/#(\w+)/g, '<a class="hashtag" data-hashtag="$1">#$1</a>')
      .replace(/@(\w+)/g, '<a class="mention" href="#/profile/$1">@$1</a>');
  }

  return (
    <article className="post-card">
      <div className="post-card-avatar">
        <Link to={`/profile/${user.id || ''}`} onClick={(e) => e.stopPropagation()}>
          {avatar
            ? <img src={avatar} alt="" className="avatar" loading="lazy" />
            : <div className="avatar avatar-placeholder">{initials}</div>
          }
        </Link>
      </div>
      <div className="post-card-body">
        {isRepost && repostedBy && (
          <div className="post-card-repost-indicator">
            🔁 {escapeHtml(repostedBy.name || '')} repostou
          </div>
        )}
        <div className="post-card-header">
          <Link to={`/profile/${user.id || ''}`} className="post-card-name"
            onClick={(e) => e.stopPropagation()}>
            {escapeHtml(user.name || '')}
          </Link>
          <span className="post-card-username">@{escapeHtml(user.username || '')}</span>
          <span className="post-card-dot">·</span>
          <span className="post-card-time">{time}</span>
        </div>
        <div
          className="post-card-content"
          dangerouslySetInnerHTML={{ __html: renderContent(post?.content || '') }}
        />
        {imageUrl && (
          <div className="post-card-images single">
            <img src={imageUrl} alt="Imagem do post" loading="lazy" />
          </div>
        )}
        <div className="post-card-actions">
          <button
            className={`post-action-btn ${liked ? 'liked' : ''}`}
            onClick={(e) => { e.stopPropagation(); onLike?.(post.id); }}
          >
            <span>{liked ? '❤️' : '🤍'}</span>
            {likeCount > 0 && <span>{likeCount}</span>}
          </button>
          <button
            className="post-action-btn"
            onClick={(e) => { e.stopPropagation(); onComment?.(post.id); }}
          >
            <span>💬</span>
            {commentCount > 0 && <span>{commentCount}</span>}
          </button>
          <button
            className="post-action-btn"
            onClick={(e) => { e.stopPropagation(); onRepost?.(post.id); }}
          >
            <span>🔁</span>
            {repostCount > 0 && <span>{repostCount}</span>}
          </button>
          <button
            className="post-action-btn"
            onClick={(e) => { e.stopPropagation(); onShare?.(post.id); }}
          >
            <span>📤</span>
          </button>
        </div>
      </div>
    </article>
  );
}
