import Component from '../components/Component.js';
import NotificationItem from '../components/NotificationItem.js';
import InfiniteScroll from '../components/InfiniteScroll.js';
import { loadNotifications, markAllAsRead, markAsRead } from '../services/notification.service.js';
import { formatRelativeTime } from '../utils/format.js';

export default class NotificationsPage extends Component {
  constructor(options = {}) {
    super(options);
    this.state = {
      notifications: [],
      isLoading: true,
      page: 0,
      hasMore: true,
      filter: 'all',
    };
    this._notifInstances = [];
  }

  mounted() {
    this._loadNotifications();
  }

  async _loadNotifications() {
    this.state.isLoading = true;
    this.render();
    try {
      const data = await loadNotifications(0);
      this.state.notifications = data.content || data || [];
      this.state.hasMore = data.last === false;
    } catch {
      this.state.notifications = [];
    } finally {
      this.state.isLoading = false;
      this.render();
    }
  }

  template() {
    const { notifications, isLoading, filter } = this.state;

    const filters = [
      { value: 'all', label: 'Todas' },
      { value: 'like', label: 'Curtidas' },
      { value: 'comment', label: 'Comentários' },
      { value: 'follow', label: 'Seguidores' },
    ];

    const filtered = filter === 'all'
      ? notifications
      : notifications.filter(n => n.type?.toLowerCase() === filter);

    const unreadCount = notifications.filter(n => !n.read).length;

    return `
      <div class="notifications-page">
        <div class="page-header">
          <div class="flex items-center justify-between">
            <h2 class="page-title">Notificações</h2>
            ${unreadCount > 0 ? '<button class="btn btn-ghost btn-sm" data-mark-read>Marcar tudo como lido</button>' : ''}
          </div>
          <div style="display:flex;gap:8px;margin-top:8px;flex-wrap:wrap">
            ${filters.map(f => `
              <span class="chip ${filter === f.value ? 'chip-active' : ''}" data-filter="${f.value}">${f.label}</span>
            `).join('')}
          </div>
        </div>

        ${isLoading
          ? '<div class="loading-container"><div class="spinner spinner-lg"></div></div>'
          : filtered.length === 0
            ? '<div class="empty-state"><div class="empty-state-icon">🔔</div><div class="empty-state-text">Nenhuma notificação</div></div>'
            : `<div data-notif-list>
                ${filtered.map((n, i) => `<div data-notif-slot="${i}"></div>`).join('')}
              </div>`
        }
        <div data-scroll-sentinel></div>
      </div>
    `;
  }

  updated() {
    this._renderNotifications();
    this._setupInfiniteScroll();
  }

  _renderNotifications() {
    for (const inst of this._notifInstances) inst.destroy();
    this._notifInstances = [];

    const parent = this.container?.querySelector('[data-notif-list]');
    if (!parent) return;

    const filtered = this.state.filter === 'all'
      ? this.state.notifications
      : this.state.notifications.filter(n => n.type?.toLowerCase() === this.state.filter);

    filtered.forEach((n, idx) => {
      const slot = parent.querySelector(`[data-notif-slot="${idx}"]`);
      if (!slot) return;
      const inst = new NotificationItem({
        container: slot,
        props: { notification: n },
      });
      inst.mount(slot);
      slot.addEventListener('click', () => this._handleNotifClick(n));
      this._notifInstances.push(inst);
    });
  }

  _setupInfiniteScroll() {
    if (this._scroll) this._scroll.destroy();
    const sentinel = this.container?.querySelector('[data-scroll-sentinel]');
    if (!sentinel) return;
    this._scroll = new InfiniteScroll({
      container: this.container,
      props: { sentinel, onLoad: () => this._loadMore() },
    });
    this._scroll.mount(this.container);
  }

  async _loadMore() {
    if (!this.state.hasMore) return;
    this.state.page++;
    try {
      const data = await loadNotifications(this.state.page);
      const newItems = data.content || data || [];
      this.state.notifications = [...this.state.notifications, ...newItems];
      this.state.hasMore = data.last === false;
      this.render();
    } catch { this.state.page--; }
  }

  events() {
    return {
      'click [data-mark-read]': '_handleMarkAllRead',
      'click [data-filter]': '_handleFilter',
    };
  }

  async _handleMarkAllRead() {
    try {
      await markAllAsRead();
      this.state.notifications = this.state.notifications.map(n => ({ ...n, read: true }));
      this.render();
    } catch {}
  }

  _handleFilter(e) {
    this.state.filter = e.currentTarget.dataset.filter;
    this.render();
  }

  async _handleNotifClick(notif) {
    if (!notif.read) {
      try {
        await markAsRead(notif.id);
        notif.read = true;
        this.render();
      } catch {}
    }
    if (notif.link) {
      window.location.hash = notif.link;
    }
  }

  destroy() {
    for (const inst of this._notifInstances) inst.destroy();
    if (this._scroll) this._scroll.destroy();
    super.destroy();
  }
}
