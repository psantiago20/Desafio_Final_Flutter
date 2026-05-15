import { NavLink } from 'react-router-dom';

export default function BottomNav() {
  const links = [
    { to: '/feed', icon: '🏠', label: 'Feed' },
    { to: '/explore', icon: '🔍', label: 'Explorar' },
    { to: '/groups', icon: '👥', label: 'Grupos' },
    { to: '/notifications', icon: '🔔', label: 'Notif.' },
    { to: '/messages', icon: '💬', label: 'Msg' },
  ];

  return (
    <nav id="bottom-nav" className="bottom-nav">
      <div className="bottom-nav-inner">
        {links.map(link => (
          <NavLink key={link.to} to={link.to}
            className={({ isActive }) => `bottom-nav-item ${isActive ? 'active' : ''}`}>
            <span className="bottom-nav-icon">{link.icon}</span>
            <span className="bottom-nav-label">{link.label}</span>
          </NavLink>
        ))}
      </div>
    </nav>
  );
}
