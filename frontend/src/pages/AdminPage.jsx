import { useState, useEffect } from 'react';
import LoadingSpinner from '../components/LoadingSpinner';
import { getStatsApi, getLeaderboardApi } from '../api/gamification.api';
import { searchUsersApi } from '../api/user.api';
import { formatNumber } from '../utils/format';
import { escapeHtml, getInitials } from '../utils/helpers';

export default function AdminPage() {
  const [stats, setStats] = useState(null);
  const [leaderboard, setLeaderboard] = useState([]);
  const [users, setUsers] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function load() {
      setIsLoading(true);
      try {
        const [s, lData] = await Promise.all([
          getStatsApi().catch(() => null),
          getLeaderboardApi({ page: 0, size: 20 }).catch(() => ({ content: [] })),
        ]);
        setStats(s);
        setLeaderboard(lData.content || lData || []);
      } catch {}
      setIsLoading(false);
    }
    load();
  }, []);

  const handleSearch = async (e) => {
    const q = e.target.value;
    setSearchQuery(q);
    if (!q.trim()) { setUsers([]); return; }
    try {
      const data = await searchUsersApi({ q, page: 0, size: 20 });
      setUsers(data.content || data || []);
    } catch { setUsers([]); }
  };

  if (isLoading) return <LoadingSpinner size="lg" />;

  const metrics = [
    { label: 'Usuários', value: formatNumber(stats?.totalUsers || 0) },
    { label: 'Posts', value: formatNumber(stats?.totalPosts || 0) },
    { label: 'Grupos', value: formatNumber(stats?.totalGroups || 0) },
    { label: 'Mentorias', value: formatNumber(stats?.totalMentorships || 0) },
  ];

  return (
    <div className="admin-page">
      <div className="page-header">
        <h2 className="page-title">Painel Administrativo</h2>
      </div>

      <div style={{ padding: 'var(--spacing-md) var(--spacing-lg)', borderBottom: '1px solid var(--border-primary)' }}>
        <h3 style={{ marginBottom: 12 }}>Métricas</h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(150px,1fr))', gap: 12 }}>
          {metrics.map(m => (
            <div key={m.label} style={{ background: 'var(--bg-secondary)', padding: 16, borderRadius: 'var(--radius-md)', textAlign: 'center' }}>
              <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--accent-primary)' }}>{m.value}</div>
              <div className="text-muted" style={{ fontSize: 13 }}>{m.label}</div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ padding: 'var(--spacing-md) var(--spacing-lg)', borderBottom: '1px solid var(--border-primary)' }}>
        <h3 style={{ marginBottom: 12 }}>Leaderboard</h3>
        {leaderboard.length === 0
          ? <div className="text-muted">Nenhum dado disponível</div>
          : leaderboard.slice(0, 10).map((u, i) => (
              <div key={u.id || i} className="leaderboard-item">
                <div className={`leaderboard-rank ${i < 3 ? 'top' : ''}`}>#{i + 1}</div>
                <div className="avatar avatar-sm avatar-placeholder" style={{ fontSize: 10 }}>
                  {getInitials(u.name || u.username)}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 600, fontSize: 14 }}>{escapeHtml(u.name || u.username || '')}</div>
                  <div className="text-muted" style={{ fontSize: 12 }}>{escapeHtml(u.username || '')}</div>
                </div>
                <div className="leaderboard-score">{formatNumber(u.points || u.score || 0)} pts</div>
              </div>
            ))
        }
      </div>

      <div style={{ padding: 'var(--spacing-md) var(--spacing-lg)' }}>
        <h3 style={{ marginBottom: 12 }}>Gerenciar Usuários</h3>
        <div className="search-bar mb-md">
          <span className="search-icon">🔍</span>
          <input type="search" placeholder="Buscar usuários..." value={searchQuery} onChange={handleSearch} />
        </div>
        {users.length === 0
          ? <div className="text-muted">Busque por usuários para gerenciar</div>
          : users.map(u => (
              <div key={u.id} className="flex items-center justify-between" style={{ padding: '8px 0', borderBottom: '1px solid var(--border-primary)' }}>
                <div className="flex items-center gap-sm">
                  <div className="avatar avatar-sm avatar-placeholder" style={{ fontSize: 10 }}>{getInitials(u.name)}</div>
                  <div>
                    <div style={{ fontWeight: 600, fontSize: 14 }}>{escapeHtml(u.name || '')}</div>
                    <div className="text-muted" style={{ fontSize: 12 }}>@{escapeHtml(u.username || '')}</div>
                  </div>
                </div>
                <span className="chip">{u.role || 'USER'}</span>
              </div>
            ))
        }
      </div>
    </div>
  );
}
