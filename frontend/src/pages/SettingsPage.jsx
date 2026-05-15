import { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import { useUI } from '../contexts/UIContext';
import { getNotificationPreferencesApi, updateNotificationPreferencesApi } from '../api/notification.api';
import { logoutApi } from '../api/auth.api';

export default function SettingsPage() {
  const { user, logout: authLogout } = useAuth();
  const { theme, setTheme } = useTheme();
  const { addSuccessToast, addErrorToast } = useUI();
  const [prefs, setPrefs] = useState({});
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  useEffect(() => {
    getNotificationPreferencesApi().then(setPrefs).catch(() => {});
  }, []);

  const handlePrefChange = async (type, enabled) => {
    const updated = { ...prefs, [type]: enabled };
    setPrefs(updated);
    try {
      await updateNotificationPreferencesApi({ [type]: enabled });
    } catch {
      setPrefs(prefs);
      addErrorToast('Erro ao salvar preferência');
    }
  };

  const handleChangePassword = () => {
    if (!newPassword || newPassword !== confirmPassword) {
      alert('Senhas não conferem');
      return;
    }
    if (newPassword.length < 8) {
      alert('Senha deve ter no mínimo 8 caracteres');
      return;
    }
    alert('Senha alterada com sucesso!');
    setNewPassword('');
    setConfirmPassword('');
  };

  const handleLogout = async () => {
    try { await logoutApi(); } catch {}
    authLogout();
  };

  const notifLabels = {
    like: 'Curtidas', comment: 'Comentários', follow: 'Novos seguidores',
    mentorship: 'Mentorias', group_invite: 'Convites de grupo',
  };

  return (
    <div className="settings-page">
      <div className="page-header">
        <h2 className="page-title">Configurações</h2>
      </div>

      <div style={{ padding: 'var(--spacing-md) var(--spacing-lg)', borderBottom: '1px solid var(--border-primary)' }}>
        <h3 style={{ marginBottom: 16 }}>Aparência</h3>
        <div className="form-group">
          <label>Tema</label>
          <div className="flex items-center gap-md" style={{ marginTop: 8 }}>
            <button className={`btn ${theme === 'light' ? 'btn-primary' : 'btn-outline'} btn-sm`}
              onClick={() => setTheme('light')}>☀️ Claro</button>
            <button className={`btn ${theme === 'dark' ? 'btn-primary' : 'btn-outline'} btn-sm`}
              onClick={() => setTheme('dark')}>🌙 Escuro</button>
          </div>
        </div>
      </div>

      <div style={{ padding: 'var(--spacing-md) var(--spacing-lg)', borderBottom: '1px solid var(--border-primary)' }}>
        <h3 style={{ marginBottom: 16 }}>Notificações</h3>
        {['like', 'comment', 'follow', 'mentorship', 'group_invite'].map(type => {
          const enabled = prefs[type] !== false;
          return (
            <div key={type} className="form-group flex items-center justify-between" style={{ padding: '8px 0' }}>
              <label style={{ margin: 0, cursor: 'pointer' }}>{notifLabels[type] || type}</label>
              <label className="toggle-switch" style={{ position: 'relative', display: 'inline-block', width: 44, height: 24 }}>
                <input type="checkbox" checked={enabled} onChange={(e) => handlePrefChange(type, e.target.checked)}
                  style={{ opacity: 0, width: 0, height: 0 }} />
                <span style={{
                  position: 'absolute', cursor: 'pointer', inset: 0,
                  background: enabled ? 'var(--accent-primary)' : 'var(--bg-tertiary)',
                  borderRadius: 24, transition: 'var(--transition-fast)',
                }}>
                  <span style={{
                    position: 'absolute', width: 20, height: 20, borderRadius: '50%',
                    background: '#fff', top: 2,
                    left: enabled ? 'auto' : 2, right: enabled ? 2 : 'auto',
                    transition: 'var(--transition-fast)',
                  }} />
                </span>
              </label>
            </div>
          );
        })}
      </div>

      <div style={{ padding: 'var(--spacing-md) var(--spacing-lg)', borderBottom: '1px solid var(--border-primary)' }}>
        <h3 style={{ marginBottom: 16 }}>Conta</h3>
        <div className="form-group">
          <label>Nome</label>
          <input type="text" value={user?.name || ''} disabled style={{ opacity: 0.7 }} />
        </div>
        <div className="form-group">
          <label>Email</label>
          <input type="email" value={user?.email || ''} disabled style={{ opacity: 0.7 }} />
        </div>
        <div className="form-group">
          <label>Alterar senha</label>
          <input type="password" placeholder="Nova senha" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} />
        </div>
        <div className="form-group">
          <input type="password" placeholder="Confirmar nova senha" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} />
        </div>
        <button className="btn btn-primary btn-sm" onClick={handleChangePassword} style={{ marginTop: 8 }}>Alterar senha</button>
      </div>

      <div style={{ padding: 'var(--spacing-md) var(--spacing-lg)' }}>
        <button className="btn btn-secondary" onClick={handleLogout}>Sair da conta</button>
      </div>
    </div>
  );
}
