import Component from '../components/Component.js';
import authStore from '../state/auth.store.js';
import { updateProfile, uploadAvatar, uploadBanner } from '../services/user.service.js';

export default class ProfileEditPage extends Component {
  constructor(options = {}) {
    super(options);
    const user = authStore.get('user') || {};
    this.state = {
      name: user.name || '',
      username: user.username || '',
      bio: user.bio || '',
      location: user.location || '',
      institution: user.institution || '',
      avatarUrl: user.avatarUrl || '',
      bannerUrl: user.bannerUrl || '',
      interests: user.interests || [],
      errors: {},
      isSaving: false,
    };
  }

  template() {
    const { name, username, bio, location, institution, avatarUrl, bannerUrl, errors, isSaving } = this.state;
    const initials = name ? this._getInitials(name) : '?';

    return `
      <div class="profile-page">
        <div class="page-header">
          <div class="flex items-center gap-md">
            <a href="#/profile" class="nav-icon-btn">←</a>
            <h2 class="page-title">Editar Perfil</h2>
          </div>
        </div>

        <div class="profile-edit-form">
          <div class="banner-upload" style="height:160px;background:var(--bg-tertiary);border-radius:var(--radius-lg);overflow:hidden;margin-bottom:48px;position:relative">
            ${bannerUrl ? `<img src="${bannerUrl}" style="width:100%;height:100%;object-fit:cover" />` : '<div style="height:100%"></div>'}
            <div class="upload-overlay">
              <span data-banner-upload>📷 Alterar banner</span>
            </div>
            <input type="file" accept="image/*" data-banner-input style="display:none" />
          </div>

          <div class="avatar-upload" style="width:96px;height:96px;margin:-72px 0 16px 16px;position:relative;border:4px solid var(--bg-primary);border-radius:50%">
            ${avatarUrl
              ? `<img src="${avatarUrl}" style="width:100%;height:100%;border-radius:50%;object-fit:cover" />`
              : `<div class="avatar avatar-xl avatar-placeholder" style="font-size:32px">${initials}</div>`
            }
            <div class="upload-overlay" style="border-radius:50%">
              <span data-avatar-upload>📷</span>
            </div>
            <input type="file" accept="image/*" data-avatar-input style="display:none" />
          </div>

          <div class="form-group">
            <label>Nome</label>
            <input type="text" value="${this._esc(name)}" data-field="name" />
            ${errors.name ? `<div class="form-error">${errors.name}</div>` : ''}
          </div>

          <div class="form-group">
            <label>Nome de usuário</label>
            <input type="text" value="${this._esc(username)}" data-field="username" />
            ${errors.username ? `<div class="form-error">${errors.username}</div>` : ''}
          </div>

          <div class="form-group">
            <label>Bio</label>
            <textarea data-field="bio" maxlength="500">${this._esc(bio)}</textarea>
          </div>

          <div class="form-group">
            <label>Localização</label>
            <input type="text" value="${this._esc(location)}" data-field="location" />
          </div>

          <div class="form-group">
            <label>Instituição</label>
            <input type="text" value="${this._esc(institution)}" data-field="institution" />
          </div>

          <div class="flex gap-md" style="margin-top:24px">
            <button class="btn btn-primary" data-save ${isSaving ? 'disabled' : ''}>
              ${isSaving ? 'Salvando...' : 'Salvar'}
            </button>
            <a href="#/profile" class="btn btn-secondary">Cancelar</a>
          </div>
        </div>
      </div>
    `;
  }

  events() {
    return {
      'change [data-field]': '_handleFieldChange',
      'click [data-save]': '_handleSave',
      'change [data-avatar-input]': '_handleAvatarUpload',
      'click [data-avatar-upload]': '_triggerAvatarInput',
      'change [data-banner-input]': '_handleBannerUpload',
      'click [data-banner-upload]': '_triggerBannerInput',
    };
  }

  _esc(str) {
    if (!str) return '';
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  _getInitials(name) {
    if (!name) return '?';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  _handleFieldChange(e) {
    const field = e.currentTarget.dataset.field;
    if (field) {
      this.state[field] = e.currentTarget.value;
    }
  }

  _triggerAvatarInput() {
    this.container?.querySelector('[data-avatar-input]')?.click();
  }

  _triggerBannerInput() {
    this.container?.querySelector('[data-banner-input]')?.click();
  }

  async _handleAvatarUpload(e) {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const result = await uploadAvatar(file);
      this.state.avatarUrl = result.url;
      this.render();
    } catch {}
  }

  async _handleBannerUpload(e) {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const result = await uploadBanner(file);
      this.state.bannerUrl = result.url;
      this.render();
    } catch {}
  }

  async _handleSave() {
    const errors = {};
    if (!this.state.name.trim()) errors.name = 'Nome é obrigatório';

    if (Object.keys(errors).length) {
      this.state.errors = errors;
      this.render();
      return;
    }

    this.state.isSaving = true;
    this.render();

    try {
      await updateProfile({
        name: this.state.name,
        username: this.state.username,
        bio: this.state.bio,
        location: this.state.location,
        institution: this.state.institution,
      });
      window.location.hash = '#/profile';
    } catch {
      this.state.isSaving = false;
      this.render();
    }
  }
}
