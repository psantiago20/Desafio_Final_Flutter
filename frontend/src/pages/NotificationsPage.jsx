import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import NotificationItem from '../components/NotificationItem';
import LoadingSpinner from '../components/LoadingSpinner';
import useInfiniteScroll from '../hooks/useInfiniteScroll';
import { getNotificationsApi, markAllNotificationsReadApi, markNotificationReadApi } from '../api/notification.api';
import { useUI } from '../contexts/UIContext';

export default function NotificationsPage() {
  const navigate = useNavigate();
  const { addSuccessToast } = useUI();
  const [notifications, setNotifications] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [filter, setFilter] = useState('all');

  const filters = [
    { value: 'all', label: 'Todas' },
    { value: 'like', label: 'Curtidas' },
    { value: 'comment', label: 'Comentários' },
    { value: 'follow', label: 'Seguidores' },
  ];

  const loadNotifications = useCallback(async (p) => {
    setIsLoading(true);
    try {
      const data = await getNotificationsApi({ page: p, size: 20 });
      const items = data.content || data || [];
      if (p === 0) setNotifications(items);
      else setNotifications(prev => [...prev, ...items]);
      setHasMore(data.last === false);
      setPage(p);
    } catch { setNotifications([]); }
    finally { setIsLoading(false); }
  }, []);

  useEffect(() => { loadNotifications(0); }, [loadNotifications]);

  const loadMore = useCallback(async () => {
    if (!hasMore) return loadNotifications(page + 1);
  }, [hasMore, page, loadNotifications]);

  const { sentinelRef } = useInfiniteScroll(loadMore, { enabled: hasMore && !isLoading });

  const handleMarkAllRead = async () => {
    try {
      await markAllNotificationsReadApi();
      setNotifications(prev => prev.map(n => ({ ...n, read: true })));
      addSuccessToast('Todas lidas!');
    } catch {}
  };

  const handleNotifClick = async (notif) => {
    if (!notif.read) {
      try {
        await markNotificationReadApi(notif.id);
        setNotifications(prev => prev.map(n => n.id === notif.id ? { ...n, read: true } : n));
      } catch {}
    }
    if (notif.link) navigate(notif.link);
  };

  const filtered = filter === 'all'
    ? notifications
    : notifications.filter(n => n.type?.toLowerCase() === filter);

  const unreadCount = notifications.filter(n => !n.read).length;

  return (
    <div className="notifications-page">
      <div className="page-header">
        <div className="flex items-center justify-between">
          <h2 className="page-title">Notificações</h2>
          {unreadCount > 0 && (
            <button className="btn btn-ghost btn-sm" onClick={handleMarkAllRead}>
              Marcar tudo como lido
            </button>
          )}
        </div>
        <div style={{ display: 'flex', gap: 8, marginTop: 8, flexWrap: 'wrap' }}>
          {filters.map(f => (
            <span key={f.value}
              className={`chip ${filter === f.value ? 'chip-active' : ''}`}
              onClick={() => setFilter(f.value)}>
              {f.label}
            </span>
          ))}
        </div>
      </div>

      {isLoading
        ? <LoadingSpinner size="lg" />
        : filtered.length === 0
          ? <div className="empty-state"><div className="empty-state-icon">🔔</div><div className="empty-state-text">Nenhuma notificação</div></div>
          : <div>
              {filtered.map(n => (
                <div key={n.id} onClick={() => handleNotifClick(n)} style={{ cursor: 'pointer' }}>
                  <NotificationItem notification={n} />
                </div>
              ))}
              {!hasMore && <div className="text-center text-muted py-md" style={{ padding: 16 }}>Você viu tudo!</div>}
              <div ref={sentinelRef} className="infinite-scroll-trigger" />
            </div>
      }
    </div>
  );
}
