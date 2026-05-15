import Component from '../components/Component.js';
import authStore from '../state/auth.store.js';
import { getTheme, setTheme, toggleTheme } from '../services/theme.service.js';
import { updateNotificationPreferences, loadNotificationPreferences } from '../services/notification.service.js';
import { logout } from '../services/auth.service.js';

export default class SettingsPage extends Component {
  constructor(options = {}) {
    super(options);
    const theme = getTheme();
    this.state = {
      theme,
      prefs: {},
    };
  }

  mounted() {
    this._loadPrefs();
  }

  async _loadPrefs() {
    try {
      const prefs = await loadNotificationPreferences();
      this.state.prefs = prefs;
      this.render();
    } catch {}
  }

  template() {
    const user = authStore.get('user');
    const { theme, prefs } = this.state;

    return `
      <div class="settings-page">
        <div class="page-header">
          <h2 class="page-title">Configurações</h2>
        </div>

        <div style="padding:var(--spacing-md) var(--spacing-lg);border-bottom:1px solid var(--border-primary)">
          <h3 style="margin-bottom:16px">Aparência</h3>
          <div class="form-group">
            <label>Tema</label>
            <div class="flex items-center gap-md" style="margin-top:8px">
              <button class="btn ${theme === 'light' ? 'btn-primary' : 'btn-outline'} btn-sm" data-theme-light>☀️ Claro</button>
              <button class="btn ${theme === 'dark' ? 'btn-primary' : 'btn-outline'} btn-sm" data-theme-dark>🌙 Escuro</button>
            </div>
          </div>
        </div>

        <div style="padding:var(--spacing-md) var(--spacing-lg);border-bottom:1px solid var(--border-primary)">
          <h3 style="margin-bottom:16px">Notificações</h3>

          ${['like', 'comment', 'follow', 'mentorship', 'group_invite'].map(type => {
            const labels = { like: 'Curtidas', comment: 'Comentários', follow: 'Novos seguidores', mentorship: 'Mentorias', group_invite: 'Convites de grupo' };
            const enabled = prefs[type] !== false;
            return `
              <div class="form-group flex items-center justify-between" style="padding:8px 0">
                <label style="margin:0;cursor:pointer">${labels[type] || type}</label>
                <label class="toggle-switch" style="position:relative;display:inline-block;width:44px;height:24px">
                  <input type="checkbox" data-pref="${type}" ${enabled ? 'checked' : ''} style="opacity:0;width:0;height:0" />
                  <span style="position:absolute;cursor:pointer;inset:0;background:${enabled ? 'var(--accent-primary)' : 'var(--bg-tertiary)'};border-radius:24px;transition:var(--transition-fast)">
                    <span style="position:absolute;width:20px;height:20px;border-radius:50%;background:#fff;top:2px;${enabled ? 'right:2px' : 'left:2px'};transition:var(--transition-fast)"></span>
                  </span>
                </label>
              </div>
            `;
          }).join('')}
        </div>

        <div style="padding:var(--spacing-md) var(--spacing-lg);border-bottom:1px solid var(--border-primary)">
          <h3 style="margin-bottom:16px">Conta</h3>
          <div class="form-group">
            <label>Nome</label>
            <input type="text" value="${user?.name || ''}" disabled style="opacity:0.7" />
          </div>
          <div class="form-group">
            <label>Email</label>
            <input type="email" value="${user?.email || ''}" disabled style="opacity:0.7" />
          </div>
          <div class="form-group">
            <label>Alterar senha</label>
            <input type="password" placeholder="Nova senha" data-new-password />
          </div>
          <div class="form-group">
            <input type="password" placeholder="Confirmar nova senha" data-confirm-password />
          </div>
          <button class="btn btn-primary btn-sm" data-change-password style="margin-top:8px">Alterar senha</button>
        </div>

        <div style="padding:var(--spacing-md) var(--spacing-lg)">
          <button class="btn btn-secondary" data-logout>Sair da conta</button>
        </div>
      </div>
    `;
  }

  events() {
    return {
      'click [data-theme-light]': () => this._setTheme('light'),
      'click [data-theme-dark]': () => this._setTheme('dark'),
      'click [data-logout]': '_handleLogout',
      'change [data-pref]': '_handlePrefChange',
      'click [data-change-password]': '_handleChangePassword',
    };
  }

  _setTheme(newTheme) {
    setTheme(newTheme);
    this.state.theme = newTheme;
    this.render();
  }

  _handleLogout() {
    logout();
  }

  async _handlePrefChange(e) {
    const type = e.currentTarget.dataset.pref;
    const enabled = e.currentTarget.checked;
    this.state.prefs[type] = enabled;
    try {
      await updateNotificationPreferences({ [type]: enabled });
    } catch {
      e.currentTarget.checked = !enabled;
    }
  }

  _handleChangePassword() {
    const modalRoot = document.getElementById('modal-root');
    if (!modalRoot) return;
    const newPass = this.container?.querySelector('[data-new-password]')?.value;
    const confirm = this.container?.querySelector('[data-confirm-password]')?.value;
    if (!newPass || newPass !== confirm) {
      alert('Senhas não conferem');
      return;
    }
    if (newPass.length < 8) {
      alert('Senha deve ter no mínimo 8 caracteres');
      return;
    }
    // API call would go here
    alert('Senha alterada com sucesso!');
  }
}
