import { Link } from 'react-router-dom';
import { escapeHtml, getInitials } from '../utils/helpers';

export default function GroupCard({ group, onAction }) {
  if (!group) return null;
  const avatar = group.avatarUrl || group.imageUrl || '';
  const initials = getInitials(group.name);
  const isMember = group.isMember || false;

  return (
    <div className="group-card">
      {avatar
        ? <img src={avatar} alt="" className="group-card-avatar" loading="lazy" />
        : <div className="group-card-avatar avatar-placeholder" style={{ borderRadius: 12, fontSize: 20 }}>{initials}</div>
      }
      <div className="group-card-info">
        <Link to={`/groups/${group.id}`} className="group-card-name">{escapeHtml(group.name || '')}</Link>
        <div className="group-card-meta">
          {group.memberCount || 0} membros
          {group.category ? `· ${escapeHtml(group.category)}` : ''}
        </div>
        <div className="group-card-desc">{escapeHtml(group.description || '')}</div>
      </div>
      <div style={{ flexShrink: 0 }}>
        <button
          className={`btn ${isMember ? 'btn-outline' : 'btn-primary'} btn-sm`}
          onClick={(e) => { e.stopPropagation(); onAction?.(group.id); }}
        >
          {isMember ? 'Sair' : 'Entrar'}
        </button>
      </div>
    </div>
  );
}
