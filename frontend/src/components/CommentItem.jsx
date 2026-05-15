import { Link } from 'react-router-dom';
import { formatRelativeTime } from '../utils/format';
import { escapeHtml, getInitials } from '../utils/helpers';

export default function CommentItem({ comment, onLike, onReply }) {
  if (!comment) return null;
  const user = comment.author || comment.user || {};
  const avatar = user.avatarUrl || '';
  const initials = getInitials(user.name);
  const time = comment.createdAt ? formatRelativeTime(comment.createdAt) : '';
  const liked = comment.liked || false;
  const replies = comment.replies || [];

  function renderContent(text) {
    if (!text) return '';
    return escapeHtml(text)
      .replace(/#(\w+)/g, '<span class="hashtag">#$1</span>')
      .replace(/@(\w+)/g, '<span class="mention">@$1</span>');
  }

  return (
    <div className="comment-item">
      <div className="post-card-avatar">
        <Link to={`/profile/${user.id || ''}`}>
          {avatar
            ? <img src={avatar} alt="" className="avatar avatar-sm" loading="lazy" />
            : <div className="avatar avatar-sm avatar-placeholder" style={{ fontSize: 12 }}>{initials}</div>
          }
        </Link>
      </div>
      <div className="comment-content">
        <div style={{ background: 'var(--bg-tertiary)', borderRadius: 'var(--radius-md)', padding: '8px 12px' }}>
          <Link to={`/profile/${user.id || ''}`} className="comment-author">
            {escapeHtml(user.name || '')}
          </Link>
          <span className="text-muted" style={{ fontSize: 12 }}>@{escapeHtml(user.username || '')}</span>
          <div className="comment-text" dangerouslySetInnerHTML={{ __html: renderContent(comment.content || '') }} />
        </div>
        <div className="comment-actions">
          <span className="comment-action">{time}</span>
          <span className="comment-action" onClick={() => onLike?.(comment.id)}>
            {liked ? '❤️' : '🤍'} Curtir
          </span>
          <span className="comment-action" onClick={() => onReply?.(comment.id)}>Responder</span>
        </div>
        {replies.length > 0 && (
          <div style={{ marginLeft: 16, marginTop: 4 }}>
            {replies.map(reply => (
              <CommentItem key={reply.id} comment={reply} onLike={onLike} onReply={onReply} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
