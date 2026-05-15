import Component from '../components/Component.js';
import Feed from '../components/Feed.js';
import InfiniteScroll from '../components/InfiniteScroll.js';
import authStore from '../state/auth.store.js';
import postStore from '../state/post.store.js';
import { loadUserProfile, followUser, unfollowUser } from '../services/user.service.js';
import { loadUserPosts, loadUserLikes, likePost, unlikePost } from '../services/post.service.js';
import { formatNumber } from '../utils/format.js';
import { escapeHtml } from '../utils/helpers.js';

export default class ProfilePage extends Component {
  constructor(options = {}) {
    super(options);
    this.state = {
      user: null,
      isLoading: true,
      tab: 'posts',
      page: 0,
      hasMore: true,
      isOwnProfile: false,
      isFollowing: false,
      followersCount: 0,
      followingCount: 0,
      postsCount: 0,
    };
  }

  mounted() {
    this._loadProfile();
  }

  async _loadProfile() {
    const userId = this.props.id;
    const currentUser = authStore.get('user');

    this.state.isLoading = true;
    this.render();

    try {
      if (userId && userId !== (currentUser?.id?.toString())) {
        const profile = await loadUserProfile(userId);
        this.state.user = profile;
        this.state.isOwnProfile = false;
        this.state.isFollowing = profile.isFollowing || false;
        this.state.followersCount = profile.followersCount || 0;
        this.state.followingCount = profile.followingCount || 0;
        this.state.postsCount = profile.postsCount || 0;
        this.state.isLoading = false;
        this.render();
        this._loadUserPosts(userId);
      } else {
        const profile = currentUser;
        this.state.user = profile;
        this.state.isOwnProfile = true;
        this.state.followersCount = profile.followersCount || 0;
        this.state.followingCount = profile.followingCount || 0;
        this.state.postsCount = profile.postsCount || 0;
        this.state.isLoading = false;
        this.render();
        this._loadUserPosts(profile.id);
      }
    } catch {
      this.state.isLoading = false;
      this.render();
    }
  }

  template() {
    if (this.state.isLoading) {
      return '<div class="loading-container"><div class="spinner spinner-lg"></div></div>';
    }

    const u = this.state.user;
    if (!u) {
      return '<div class="empty-state"><div class="empty-state-text">Usuário não encontrado</div></div>';
    }

    const avatar = u.avatarUrl || '';
    const banner = u.bannerUrl || '';
    const initials = u.name ? this._getInitials(u.name) : '?';
    const isOwn = this.state.isOwnProfile;

    return `
      <div class="profile-page">
        <div class="profile-header-section">
          <div class="profile-banner-img" style="${banner ? `background-image:url(${banner})` : ''};background-size:cover;background-position:center">
            ${!banner ? '' : ''}
          </div>
        </div>

        <div class="profile-info-section">
          <div class="profile-avatar-section">
            ${avatar
              ? `<img src="${avatar}" alt="" class="avatar avatar-xl" />`
              : `<div class="avatar avatar-xl avatar-placeholder" style="font-size:36px">${initials}</div>`
            }
          </div>

          <div class="profile-action-row">
            ${isOwn
              ? `<a href="#/profile/edit" class="btn btn-outline btn-sm">Editar perfil</a>`
              : `<button class="btn ${this.state.isFollowing ? 'btn-outline' : 'btn-primary'} btn-sm" data-follow>${this.state.isFollowing ? 'Seguindo' : 'Seguir'}</button>`
            }
          </div>

          <div class="profile-display-name">${escapeHtml(u.name || '')}</div>
          <div class="profile-handle">@${escapeHtml(u.username || '')}</div>

          ${u.bio ? `<div class="profile-bio-text">${escapeHtml(u.bio)}</div>` : ''}

          <div class="profile-details">
            ${u.location ? `<span class="profile-detail-item">📍 ${escapeHtml(u.location)}</span>` : ''}
            ${u.institution ? `<span class="profile-detail-item">🏛️ ${escapeHtml(u.institution)}</span>` : ''}
          </div>

          <div class="profile-numbers">
            <span class="profile-number"><span class="profile-number-value">${formatNumber(this.state.postsCount)}</span> <span class="profile-number-label">Posts</span></span>
            <span class="profile-number"><span class="profile-number-value">${formatNumber(this.state.followersCount)}</span> <span class="profile-number-label">Seguidores</span></span>
            <span class="profile-number"><span class="profile-number-value">${formatNumber(this.state.followingCount)}</span> <span class="profile-number-label">Seguindo</span></span>
          </div>
        </div>

        <div class="profile-content-tabs">
          <div class="profile-content-tab ${this.state.tab === 'posts' ? 'active' : ''}" data-tab="posts">Posts</div>
          <div class="profile-content-tab ${this.state.tab === 'likes' ? 'active' : ''}" data-tab="likes">Curtidas</div>
          <div class="profile-content-tab ${this.state.tab === 'media' ? 'active' : ''}" data-tab="media">Mídia</div>
        </div>

        <div data-feed-container></div>
        <div data-scroll-sentinel></div>
      </div>
    `;
  }

  events() {
    return {
      'click [data-tab]': '_switchTab',
      'click [data-follow]': '_handleFollowToggle',
    };
  }

  _switchTab(e) {
    const tab = e.currentTarget.dataset.tab;
    if (tab && tab !== this.state.tab) {
      this.state.tab = tab;
      this.state.page = 0;
      this.state.hasMore = true;
      postStore.set({ posts: [], pagination: { page: 0, totalPages: 0, totalElements: 0, hasMore: true } });
      this.render();
      this._loadTabContent();
    }
  }

  _loadTabContent() {
    const userId = this.state.user?.id;
    if (!userId) return;

    if (this.state.tab === 'posts') {
      this._loadUserPosts(userId);
    } else if (this.state.tab === 'likes') {
      this._loadUserLikes(userId);
    }
  }

  async _loadUserPosts(userId) {
    try {
      postStore.set({ posts: [], pagination: { page: 0, hasMore: true } });
      await loadUserPosts(userId, 0);
    } catch {}
  }

  async _loadUserLikes(userId) {
    try {
      await loadUserLikes(userId, 0);
    } catch {}
  }

  async _handleFollowToggle() {
    const userId = this.state.user?.id;
    if (!userId) return;

    try {
      if (this.state.isFollowing) {
        await unfollowUser(userId);
        this.state.isFollowing = false;
        this.state.followersCount--;
      } else {
        await followUser(userId);
        this.state.isFollowing = true;
        this.state.followersCount++;
      }
      this.render();
    } catch {}
  }

  _getInitials(name) {
    if (!name) return '?';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  updated() {
    this._renderFeed();
    this._setupInfiniteScroll();
  }

  _renderFeed() {
    const container = this.container?.querySelector('[data-feed-container]');
    if (!container) return;
    if (this._feed) this._feed.destroy();

    const { posts, isLoading, error } = postStore.state;
    const pagination = postStore.get('pagination') || {};
    this.state.hasMore = pagination.hasMore !== false;

    this._feed = new Feed({
      container,
      state: { posts, isLoading, error, hasMore: this.state.hasMore },
      props: {
        onLike: (postId) => this._handleLike(postId),
        onComment: (postId) => { window.location.hash = `#/post/${postId}`; },
      },
    });
    this._feed.mount(container);
  }

  _setupInfiniteScroll() {
    if (this._scroll) this._scroll.destroy();
    const sentinel = this.container?.querySelector('[data-scroll-sentinel]');
    if (!sentinel) return;
    this._scroll = new InfiniteScroll({
      container: this.container,
      props: {
        sentinel,
        onLoad: () => this._loadMore(),
      },
    });
    this._scroll.mount(this.container);
  }

  async _loadMore() {
    if (!this.state.hasMore) return;
    this.state.page++;
    try {
      const userId = this.state.user?.id;
      if (!userId) return;
      let data;
      if (this.state.tab === 'posts') {
        data = await loadUserPosts(userId, this.state.page);
      } else if (this.state.tab === 'likes') {
        data = await loadUserLikes(userId, this.state.page);
      }
      this.state.hasMore = data ? !data.last : false;
    } catch {
      this.state.page--;
    }
  }

  async _handleLike(postId) {
    const posts = postStore.get('posts');
    const post = posts.find(p => p.id === postId);
    if (!post) return;
    if (post.liked) await unlikePost(postId);
    else await likePost(postId);
  }

  destroy() {
    if (this._feed) this._feed.destroy();
    if (this._scroll) this._scroll.destroy();
    super.destroy();
  }
}
