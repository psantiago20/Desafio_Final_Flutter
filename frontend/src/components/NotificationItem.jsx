import { formatRelativeTime } from '../utils/format';

export default function NotificationItem({ notification }) {
  if (!notification) return null;
  const read = notification.read || false;
  const type = (notification.type || '').toLowerCase();
  const typeIcons = {
    like: '❤️', comment: '💬', follow: '👤',
    mentorship: '🎓', group_invite: '👥', system: '🔔', repost: '🔁',
  };
  const icon = typeIcons[type] || '🔔';

  return (
    <div className={`notification-item ${read ? '' : 'unread'}`}>
      <div className="notification-icon">{icon}</div>
      <div className="notification-body">
        <div className="notification-text">{notification.message || notification.text || ''}</div>
        <div className="notification-time">{notification.createdAt ? formatRelativeTime(notification.createdAt) : ''}</div>
      </div>
      {!read && (
        <span style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--accent-primary)', flexShrink: 0, marginTop: 8 }} />
      )}
    </div>
  );
}
