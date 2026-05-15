import Component from './Component.js';

export default class Modal extends Component {
  constructor(options = {}) {
    super(options);
    this._escapeHandler = this._escapeHandler.bind(this);
  }

  mounted() {
    document.addEventListener('keydown', this._escapeHandler);
    document.body.style.overflow = 'hidden';
  }

  template() {
    const { title = '', content = '', footer = '', showClose = true, wide = false } = this.props;

    return `
      <div class="modal-overlay" data-modal-overlay>
        <div class="modal-content" style="${wide ? 'max-width:720px' : ''}">
          <div class="modal-header">
            <div class="modal-title">${title}</div>
            ${showClose ? '<button class="modal-close" data-modal-close>✕</button>' : ''}
          </div>
          <div class="modal-body" data-modal-body>
            ${typeof content === 'function' ? '' : content}
          </div>
          ${footer ? `<div class="modal-footer" style="padding:var(--spacing-md) var(--spacing-lg);border-top:1px solid var(--border-primary);display:flex;justify-content:flex-end;gap:8px">${footer}</div>` : ''}
        </div>
      </div>
    `;
  }

  events() {
    return {
      'click [data-modal-overlay]': '_handleOverlayClick',
      'click [data-modal-close]': '_handleClose',
    };
  }

  _escapeHandler(e) {
    if (e.key === 'Escape') {
      this.props.onClose?.();
    }
  }

  _handleOverlayClick(e) {
    if (e.target.dataset.modalOverlay !== undefined) {
      this.props.onClose?.();
    }
  }

  _handleClose() {
    this.props.onClose?.();
  }

  destroy() {
    document.removeEventListener('keydown', this._escapeHandler);
    document.body.style.overflow = '';
    super.destroy();
  }
}
