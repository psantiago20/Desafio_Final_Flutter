import Component from './Component.js';
import { formatRelativeTime } from '../utils/format.js';
import { escapeHtml } from '../utils/helpers.js';

export default class NotificationItem extends Component {
  template() {
    const notif = this.props.notification || {};
    const read = notif.read || false;
    const type = (notif.type || '').toLowerCase();
    const typeIcons = {
      like: '❤️',
      comment: '💬',
      follow: '👤',
      mentorship: '🎓',
      group_invite: '👥',
      system: '🔔',
      repost: '🔁',
    };
    const icon = typeIcons[type] || '🔔';

    return `
      <div class="notification-item ${read ? '' : 'unread'}" data-notif-id="${notif.id || ''}" data-notif-link="${notif.link || ''}">
        <div class="notification-icon">${icon}</div>
        <div class="notification-body">
          <div class="notification-text">${notif.message || escapeHtml(notif.text || '')}</div>
          <div class="notification-time">${notif.createdAt ? formatRelativeTime(notif.createdAt) : ''}</div>
        </div>
        ${read ? '' : '<span style="width:8px;height:8px;border-radius:50%;background:var(--accent-primary);flex-shrink:0;margin-top:8px"></span>'}
      </div>
    `;
  }
}
