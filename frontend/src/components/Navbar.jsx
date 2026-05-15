import { useState, useEffect, useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import ThemeToggle from './ThemeToggle';
import { APP_NAME } from '../constants/config';
import { getInitials } from '../utils/helpers';

export default function Navbar() {
  const { user, logout } = useAuth();
  const { theme, toggleTheme } = useTheme();
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const navigate = useNavigate();
  const dropdownRef = useRef(null);

  useEffect(() => {
    function handleClick(e) {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) {
        setDropdownOpen(false);
      }
    }
    if (dropdownOpen) {
      document.addEventListener('click', handleClick);
      return () => document.removeEventListener('click', handleClick);
    }
  }, [dropdownOpen]);

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const unread = 0;
  const avatar = user?.avatarUrl || '';
  const initials = getInitials(user?.name);

  return (
    <header id="navbar">
      <div className="nav-inner">
        <div className="flex items-center gap-md">
          <button className="nav-icon-btn mobile-menu-btn" aria-label="Menu"
            onClick={() => document.body.classList.toggle('mobile-menu-open')}>
            <span>☰</span>
          </button>
          <Link to="/feed" className="navbar-logo">{APP_NAME}</Link>
        </div>

        <div className="navbar-search">
          <span className="search-icon">🔍</span>
          <input type="search" placeholder="Buscar no Pitaya..." />
        </div>

        <div className="navbar-actions">
          <ThemeToggle />

          <Link to="/notifications" className="nav-icon-btn" title="Notificações">
            <span>🔔</span>
            {unread > 0 && <span className="badge">{unread > 9 ? '9+' : unread}</span>}
          </Link>

          <div className="user-dropdown" ref={dropdownRef}>
            <button className="nav-icon-btn user-dropdown-trigger" title="Perfil"
              onClick={() => setDropdownOpen(!dropdownOpen)}>
              {avatar
                ? <img src={avatar} alt="Avatar" className="avatar avatar-sm" />
                : <div className="avatar avatar-sm avatar-placeholder">{initials}</div>
              }
            </button>
            {dropdownOpen && (
              <div className="dropdown-menu visible">
                <Link to="/profile" className="dropdown-item" onClick={() => setDropdownOpen(false)}>
                  Meu Perfil
                </Link>
                <Link to="/settings" className="dropdown-item" onClick={() => setDropdownOpen(false)}>
                  Configurações
                </Link>
                <hr className="dropdown-divider" />
                <button className="dropdown-item" onClick={handleLogout}>Sair</button>
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
}
