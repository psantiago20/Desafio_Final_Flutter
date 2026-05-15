import Component from './Component.js';
import authStore from '../state/auth.store.js';
import { MAX_POST_LENGTH } from '../constants/config.js';
import { VISIBILITY } from '../constants/config.js';

export default class PostComposer extends Component {
  constructor(options = {}) {
    super(options);
    this.state = {
      content: '',
      visibility: VISIBILITY.PUBLIC,
      imageFile: null,
      imagePreview: null,
      isSubmitting: false,
    };
  }

  mounted() {
    this.unsub = this.subscribeTo(authStore, () => this.render());
    this._setupAutoResize();
  }

  template() {
    const user = authStore.get('user');
    const avatar = user?.avatarUrl || '';
    const initials = user?.name ? this._getInitials(user.name) : '?';
    const len = this.state.content.length;
    const remaining = MAX_POST_LENGTH - len;
    const showWarning = len > MAX_POST_LENGTH * 0.9;
    const showDanger = len >= MAX_POST_LENGTH;

    return `
      <div class="post-composer">
        <div class="flex gap-sm">
          <div class="post-card-avatar">
            ${avatar
              ? `<img src="${avatar}" alt="" class="avatar" />`
              : `<div class="avatar avatar-placeholder">${initials}</div>`
            }
          </div>
          <div class="flex-col" style="flex:1">
            <textarea
              class="post-composer-textarea"
              placeholder="O que está acontecendo?"
              data-composer-input
              maxlength="${MAX_POST_LENGTH}"
            >${this.state.content}</textarea>
            ${this.state.imagePreview ? `
              <div class="composer-image-preview" style="position:relative;display:inline-block;margin-top:8px">
                <img src="${this.state.imagePreview}" style="max-height:200px;border-radius:8px" />
                <button data-remove-image style="position:absolute;top:4px;right:4px;background:var(--bg-modal-overlay);color:#fff;border-radius:50%;width:28px;height:28px">✕</button>
              </div>
            ` : ''}
            <div class="post-composer-footer">
              <div class="post-composer-actions">
                <label class="nav-icon-btn" style="cursor:pointer" title="Adicionar imagem">
                  <span>🖼️</span>
                  <input type="file" accept="image/*" data-image-input style="display:none" />
                </label>
                <select data-visibility class="chip" style="border:none;background:var(--bg-tertiary);padding:4px 8px;font-size:12px">
                  <option value="${VISIBILITY.PUBLIC}" ${this.state.visibility === VISIBILITY.PUBLIC ? 'selected' : ''}>🌍 Público</option>
                  <option value="${VISIBILITY.FOLLOWERS}" ${this.state.visibility === VISIBILITY.FOLLOWERS ? 'selected' : ''}>👥 Seguidores</option>
                  <option value="${VISIBILITY.PRIVATE}" ${this.state.visibility === VISIBILITY.PRIVATE ? 'selected' : ''}>🔒 Privado</option>
                </select>
              </div>
              <div class="flex items-center gap-sm">
                <span class="char-counter ${showWarning ? 'warning' : ''} ${showDanger ? 'danger' : ''}">${remaining}</span>
                <button class="btn btn-primary btn-sm" data-submit ${this.state.isSubmitting || !this.state.content.trim() || showDanger ? 'disabled' : ''}>
                  ${this.state.isSubmitting ? 'Publicando...' : 'Postar'}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  events() {
    return {
      'input [data-composer-input]': '_handleInput',
      'click [data-submit]': '_handleSubmit',
      'change [data-image-input]': '_handleImageSelect',
      'click [data-remove-image]': '_handleRemoveImage',
      'change [data-visibility]': '_handleVisibilityChange',
    };
  }

  _getInitials(name) {
    if (!name) return '?';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  _handleInput(e) {
    this.state.content = e.target.value;
    this.render();
    this._setupAutoResize();
  }

  _setupAutoResize() {
    const ta = this.container?.querySelector('[data-composer-input]');
    if (ta) {
      ta.style.height = 'auto';
      ta.style.height = ta.scrollHeight + 'px';
    }
  }

  _handleImageSelect(e) {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 5 * 1024 * 1024) {
      alert('Imagem muito grande. Máximo 5MB.');
      return;
    }
    this.state.imageFile = file;
    const reader = new FileReader();
    reader.onload = (ev) => {
      this.state.imagePreview = ev.target.result;
      this.render();
    };
    reader.readAsDataURL(file);
  }

  _handleRemoveImage() {
    this.state.imageFile = null;
    this.state.imagePreview = null;
    this.render();
  }

  _handleVisibilityChange(e) {
    this.state.visibility = e.target.value;
  }

  async _handleSubmit() {
    if (this.state.isSubmitting) return;
    const content = this.state.content.trim();
    if (!content) return;

    this.state.isSubmitting = true;
    this.render();

    try {
      await this.props.onSubmit?.({
        content,
        visibility: this.state.visibility,
        imageFile: this.state.imageFile,
      });
      this.state.content = '';
      this.state.imageFile = null;
      this.state.imagePreview = null;
    } catch {
    } finally {
      this.state.isSubmitting = false;
      this.render();
      this._setupAutoResize();
    }
  }

  destroy() {
    if (this.unsub) this.unsub();
    super.destroy();
  }
}
