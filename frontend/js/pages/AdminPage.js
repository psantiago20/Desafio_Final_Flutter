import Component from '../components/Component.js';
import { loadUserStats, loadLeaderboard } from '../services/gamification.service.js';
import { searchUsers } from '../services/user.service.js';
import { formatNumber } from '../utils/format.js';
import { escapeHtml } from '../utils/helpers.js';

export default class AdminPage extends Component {
  constructor(options = {}) {
    super(options);
    this.state = {
      stats: null,
      users: [],
      leaderboard: [],
      isLoading: true,
      searchQuery: '',
    };
  }

  mounted() {
    this._loadData();
  }

  async _loadData() {
    this.state.isLoading = true;
    this.render();
    try {
      const [stats, leaderData] = await Promise.all([
        loadUserStats().catch(() => null),
        loadLeaderboard(0).catch(() => ({ content: [] })),
      ]);
      this.state.stats = stats;
      this.state.leaderboard = leaderData.content || leaderData || [];
    } catch {}
    this.state.isLoading = false;
    this.render();
  }

  template() {
    const { stats, users, leaderboard, isLoading } = this.state;

    if (isLoading) {
      return '<div class="loading-container"><div class="spinner spinner-lg"></div></div>';
    }

    return `
      <div class="admin-page">
        <div class="page-header">
          <h2 class="page-title">Painel Administrativo</h2>
        </div>

        <div style="padding:var(--spacing-md) var(--spacing-lg);border-bottom:1px solid var(--border-primary)">
          <h3 style="margin-bottom:12px">Métricas</h3>
          <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:12px">
            <div style="background:var(--bg-secondary);padding:16px;border-radius:var(--radius-md);text-align:center">
              <div style="font-size:24px;font-weight:700;color:var(--accent-primary)">${formatNumber(stats?.totalUsers || 0)}</div>
              <div class="text-muted" style="font-size:13px">Usuários</div>
            </div>
            <div style="background:var(--bg-secondary);padding:16px;border-radius:var(--radius-md);text-align:center">
              <div style="font-size:24px;font-weight:700;color:var(--accent-primary)">${formatNumber(stats?.totalPosts || 0)}</div>
              <div class="text-muted" style="font-size:13px">Posts</div>
            </div>
            <div style="background:var(--bg-secondary);padding:16px;border-radius:var(--radius-md);text-align:center">
              <div style="font-size:24px;font-weight:700;color:var(--accent-primary)">${formatNumber(stats?.totalGroups || 0)}</div>
              <div class="text-muted" style="font-size:13px">Grupos</div>
            </div>
            <div style="background:var(--bg-secondary);padding:16px;border-radius:var(--radius-md);text-align:center">
              <div style="font-size:24px;font-weight:700;color:var(--accent-primary)">${formatNumber(stats?.totalMentorships || 0)}</div>
              <div class="text-muted" style="font-size:13px">Mentorias</div>
            </div>
          </div>
        </div>

        <div style="padding:var(--spacing-md) var(--spacing-lg);border-bottom:1px solid var(--border-primary)">
          <h3 style="margin-bottom:12px">Leaderboard</h3>
          ${leaderboard.length === 0
            ? '<div class="text-muted">Nenhum dado disponível</div>'
            : leaderboard.slice(0, 10).map((u, i) => `
              <div class="leaderboard-item">
                <div class="leaderboard-rank ${i < 3 ? 'top' : ''}">#${i + 1}</div>
                <img src="${u.avatarUrl || ''}" alt="" class="avatar avatar-sm" onerror="this.style.display='none'" />
                <div style="flex:1">
                  <div style="font-weight:600;font-size:14px">${escapeHtml(u.name || u.username || '')}</div>
                  <div class="text-muted" style="font-size:12px">${escapeHtml(u.username || '')}</div>
                </div>
                <div class="leaderboard-score">${formatNumber(u.points || u.score || 0)} pts</div>
              </div>
            `).join('')
          }
        </div>

        <div style="padding:var(--spacing-md) var(--spacing-lg)">
          <h3 style="margin-bottom:12px">Gerenciar Usuários</h3>
          <div class="search-bar mb-md">
            <span class="search-icon">🔍</span>
            <input type="search" placeholder="Buscar usuários..." data-search-users />
          </div>
          <div data-user-list>
            ${users.length === 0
              ? '<div class="text-muted">Busque por usuários para gerenciar</div>'
              : users.map(u => `
                <div class="flex items-center justify-between" style="padding:8px 0;border-bottom:1px solid var(--border-primary)">
                  <div class="flex items-center gap-sm">
                    <div class="avatar avatar-sm avatar-placeholder" style="font-size:10px">${this._getInitials(u.name)}</div>
                    <div>
                      <div style="font-weight:600;font-size:14px">${escapeHtml(u.name || '')}</div>
                      <div class="text-muted" style="font-size:12px">@${escapeHtml(u.username || '')}</div>
                    </div>
                  </div>
                  <span class="chip">${u.role || 'USER'}</span>
                </div>
              `).join('')
            }
          </div>
        </div>
      </div>
    `;
  }

  events() {
    return {
      'input [data-search-users]': '_handleSearch',
    };
  }

  _getInitials(name) {
    if (!name) return '?';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  async _handleSearch(e) {
    const query = e.target.value;
    this.state.searchQuery = query;
    if (!query.trim()) {
      this.state.users = [];
      this.render();
      return;
    }
    try {
      const data = await searchUsers(query, 0);
      this.state.users = data.content || data || [];
      this.render();
    } catch {}
  }

  destroy() {
    super.destroy();
  }
}
