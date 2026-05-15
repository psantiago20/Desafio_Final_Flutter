import Component from '../components/Component.js';
import Feed from '../components/Feed.js';
import PostComposer from '../components/PostComposer.js';
import postStore from '../state/post.store.js';
import authStore from '../state/auth.store.js';
import { loadGroupDetail, joinGroup, leaveGroup, loadGroupMembers } from '../services/group.service.js';
import { createPost, likePost, unlikePost, uploadPostImage } from '../services/post.service.js';
import { escapeHtml } from '../utils/helpers.js';
import { formatNumber } from '../utils/format.js';

export default class GroupDetailPage extends Component {
  constructor(options = {}) {
    super(options);
    this.state = {
      group: null,
      members: [],
      isLoading: true,
      posts: [],
      isMember: false,
    };
  }

  mounted() {
    this._loadData();
  }

  async _loadData() {
    const groupId = this.props.id;
    if (!groupId) return;

    try {
      const group = await loadGroupDetail(groupId);
      this.state.group = group;
      this.state.isMember = group.isMember || false;
      this.state.isLoading = false;
      this.render();
    } catch {
      this.state.isLoading = false;
      this.render();
    }

    try {
      const membersData = await loadGroupMembers(groupId);
      this.state.members = membersData.content || membersData || [];
    } catch {}
  }

  template() {
    if (this.state.isLoading) {
      return '<div class="loading-container"><div class="spinner spinner-lg"></div></div>';
    }

    const g = this.state.group;
    if (!g) {
      return '<div class="empty-state"><div class="empty-state-text">Grupo não encontrado</div></div>';
    }

    const banner = g.bannerUrl || '';
    const avatar = g.avatarUrl || '';
    const initials = g.name ? this._getInitials(g.name) : 'G';

    return `
      <div class="group-detail-page">
        <div class="profile-header-section">
          <div class="profile-banner-img" style="${banner ? `background-image:url(${banner})` : ''};background-size:cover;background-position:center">
          </div>
        </div>

        <div class="profile-info-section">
          <div class="profile-avatar-section" style="top:-48px">
            ${avatar
              ? `<img src="${avatar}" alt="" class="avatar avatar-lg" />`
              : `<div class="avatar avatar-lg avatar-placeholder" style="font-size:20px">${initials}</div>`
            }
          </div>

          <div class="profile-action-row">
            <button class="btn ${this.state.isMember ? 'btn-outline' : 'btn-primary'} btn-sm" data-join-group>
              ${this.state.isMember ? 'Sair do grupo' : 'Entrar no grupo'}
            </button>
          </div>

          <div class="profile-display-name">${escapeHtml(g.name || '')}</div>
          ${g.category ? `<div class="profile-handle">${escapeHtml(g.category)}</div>` : ''}
          ${g.description ? `<div class="profile-bio-text">${escapeHtml(g.description)}</div>` : ''}

          <div class="profile-numbers">
            <span class="profile-number"><span class="profile-number-value">${formatNumber(g.memberCount || 0)}</span> <span class="profile-number-label">Membros</span></span>
          </div>
        </div>

        ${this.state.isMember ? '<div data-composer></div>' : ''}

        <div class="profile-content-tabs">
          <div class="profile-content-tab active">Posts</div>
          <div class="profile-content-tab" data-show-members>Membros (${g.memberCount || 0})</div>
        </div>

        <div data-posts></div>
      </div>
    `;
  }

  updated() {
    if (this.state.isMember) {
      this._mountComposer();
    }
    this._renderPosts();
  }

  _mountComposer() {
    const slot = this.container?.querySelector('[data-composer]');
    if (!slot) return;
    if (this._composer) return;
    this._composer = new PostComposer({
      container: slot,
      props: {
        onSubmit: (data) => this._handleCreatePost(data),
      },
    });
    this._composer.mount(slot);
  }

  _renderPosts() {
    const slot = this.container?.querySelector('[data-posts]');
    if (!slot) return;
    if (this._feed) this._feed.destroy();
    this._feed = new Feed({
      container: slot,
      state: { posts: this.state.posts, isLoading: false },
      props: {
        onLike: (postId) => this._handleLike(postId),
        onComment: (postId) => { window.location.hash = `#/post/${postId}`; },
      },
    });
    this._feed.mount(slot);
  }

  async _handleCreatePost(data) {
    const payload = { content: data.content, visibility: data.visibility, groupId: this.props.id };
    if (data.imageFile) {
      const uploadResult = await uploadPostImage(data.imageFile);
      payload.imageUrl = uploadResult.url || uploadResult.imageUrl;
    }
    try {
      const post = await createPost(payload);
      this.state.posts = [post, ...this.state.posts];
      this.render();
    } catch {}
  }

  events() {
    return {
      'click [data-join-group]': '_handleJoinToggle',
      'click [data-show-members]': '_showMembers',
    };
  }

  async _handleJoinToggle() {
    const groupId = this.props.id;
    try {
      if (this.state.isMember) {
        await leaveGroup(groupId);
        this.state.isMember = false;
        this.state.group.memberCount--;
      } else {
        await joinGroup(groupId);
        this.state.isMember = true;
        this.state.group.memberCount++;
      }
      this.render();
    } catch {}
  }

  _showMembers() {
    // Could show member list modal
  }

  _getInitials(name) {
    if (!name) return 'G';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  async _handleLike(postId) {
    const post = this.state.posts.find(p => p.id === postId);
    if (!post) return;
    if (post.liked) await unlikePost(postId);
    else await likePost(postId);
  }

  destroy() {
    if (this._composer) this._composer.destroy();
    if (this._feed) this._feed.destroy();
    super.destroy();
  }
}
