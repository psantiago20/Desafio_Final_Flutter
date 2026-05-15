import Component from './Component.js';
import uiStore, { removeToast } from '../state/ui.store.js';

export default class Toast extends Component {
  constructor(options = {}) {
    super(options);
    this.state = { toasts: [] };
  }

  mounted() {
    this.unsub = this.subscribeTo(uiStore, () => {
      this.state.toasts = uiStore.get('toasts') || [];
      this.render();
    });
  }

  template() {
    const toasts = this.state.toasts || [];

    if (!toasts.length) return '';

    return toasts.map(t => {
      const typeClass = t.type ? `toast-${t.type}` : '';
      const typeIcons = { success: '✅', error: '❌', info: 'ℹ️', warning: '⚠️' };
      const icon = typeIcons[t.type] || 'ℹ️';
      return `
        <div class="toast ${typeClass}" data-toast-id="${t.id}">
          <span>${icon}</span>
          <span>${t.message}</span>
          <span class="toast-close" data-dismiss-toast="${t.id}">✕</span>
        </div>
      `;
    }).join('');
  }

  events() {
    return {
      'click [data-dismiss-toast]': '_handleDismiss',
    };
  }

  _handleDismiss(e) {
    const id = parseInt(e.currentTarget.dataset.dismissToast, 10);
    removeToast(id);
  }

  destroy() {
    if (this.unsub) this.unsub();
    super.destroy();
  }
}
