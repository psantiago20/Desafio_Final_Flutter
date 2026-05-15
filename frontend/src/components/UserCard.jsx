import { Link } from 'react-router-dom';
import { escapeHtml, getInitials } from '../utils/helpers';

export default function UserCard({ user, onFollow, showFollowBtn = true }) {
  if (!user) return null;
  const avatar = user.avatarUrl || '';
  const initials = getInitials(user.name);
  const isFollowing = user.isFollowing || false;

  return (
    <div className="user-card">
      <Link to={`/profile/${user.id || ''}`}>
        {avatar
          ? <img src={avatar} alt="" className="avatar avatar-sm" loading="lazy" />
          : <div className="avatar avatar-sm avatar-placeholder" style={{ fontSize: 12 }}>{initials}</div>
        }
      </Link>
      <div className="user-card-info">
        <Link to={`/profile/${user.id || ''}`}>
          <div className="user-card-name">{escapeHtml(user.name || '')}</div>
          <div className="user-card-username">@{escapeHtml(user.username || '')}</div>
        </Link>
      </div>
      {showFollowBtn && (
        <button
          className={`btn ${isFollowing ? 'btn-outline' : 'btn-primary'} btn-sm`}
          onClick={(e) => { e.preventDefault(); onFollow?.(user.id); }}
        >
          {isFollowing ? 'Seguindo' : 'Seguir'}
        </button>
      )}
    </div>
  );
}
