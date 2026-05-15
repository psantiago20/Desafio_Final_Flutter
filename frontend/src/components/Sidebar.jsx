import { NavLink } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { getInitials } from '../utils/helpers';

export default function Sidebar() {
  const { user } = useAuth();
  const initials = getInitials(user?.name);

  const links = [
    { to: '/feed', label: 'Feed', icon: '🏠' },
    { to: '/explore', label: 'Explorar', icon: '🔍' },
    { to: '/groups', label: 'Grupos', icon: '👥' },
    { to: '/library', label: 'Biblioteca', icon: '📚' },
    { to: '/mentorship', label: 'Mentorias', icon: '🎓' },
    { to: '/messages', label: 'Mensagens', icon: '💬' },
    { to: '/notifications', label: 'Notificações', icon: '🔔' },
  ];

  return (
    <aside id="left-sidebar">
      <nav className="sidebar-nav">
        {user && (
          <NavLink to="/profile" className="sidebar-user">
            <div className="avatar avatar-sm">
              {user.avatarUrl
                ? <img src={user.avatarUrl} alt="" />
                : <div className="avatar avatar-sm avatar-placeholder">{initials}</div>
              }
            </div>
            <div className="sidebar-user-info">
              <span className="sidebar-user-name">{user.name}</span>
              <span className="sidebar-user-handle">@{user.username}</span>
            </div>
          </NavLink>
        )}
        {links.map(link => (
          <NavLink key={link.to} to={link.to}
            className={({ isActive }) => `sidebar-link ${isActive ? 'active' : ''}`}>
            <span className="sidebar-icon">{link.icon}</span>
            <span>{link.label}</span>
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}
