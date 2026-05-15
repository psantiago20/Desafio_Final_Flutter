import Component from '../components/Component.js';
import PostCard from '../components/PostCard.js';
import CommentItem from '../components/CommentItem.js';
import authStore from '../state/auth.store.js';
import postStore from '../state/post.store.js';
import { loadPostDetail, loadComments, createComment, likePost, unlikePost, repostPost } from '../services/post.service.js';

export default class PostDetailPage extends Component {
  constructor(options = {}) {
    super(options);
    this.state = {
      postId: this.props.id,
      commentText: '',
      comments: [],
      isSubmitting: false,
    };
    this._postCard = null;
    this._commentInstances = [];
  }

  mounted() {
    this._loadData();
    this.unsubPosts = this.subscribeTo(postStore, () => this.render());
  }

  async _loadData() {
    if (!this.state.postId) return;
    try {
      await loadPostDetail(this.state.postId);
    } catch {}
    try {
      const data = await loadComments(this.state.postId);
      this.state.comments = data.content || data || [];
      this.render();
    } catch {}
  }

  template() {
    const post = postStore.get('currentPost');
    const { comments, commentText, isSubmitting } = this.state;
    const user = authStore.get('user');
    const avatar = user?.avatarUrl || '';
    const initials = user?.name ? this._getInitials(user.name) : '?';

    if (!post) {
      const isLoading = postStore.get('isLoading');
      if (isLoading) return '<div class="loading-container"><div class="spinner spinner-lg"></div></div>';
      return '<div class="empty-state"><div class="empty-state-text">Post não encontrado</div></div>';
    }

    return `
      <div class="post-detail-page">
        <div class="page-header">
          <div class="flex items-center gap-md">
            <a href="javascript:history.back()" class="nav-icon-btn">←</a>
            <h2 class="page-title">Post</h2>
          </div>
        </div>

        <div data-post-card></div>

        <div style="padding:var(--spacing-md) var(--spacing-lg);border-bottom:1px solid var(--border-primary)">
          <div class="flex gap-sm">
            ${avatar
              ? `<img src="${avatar}" alt="" class="avatar avatar-sm" />`
              : `<div class="avatar avatar-sm avatar-placeholder" style="font-size:12px">${initials}</div>`
            }
            <div style="flex:1;display:flex;gap:8px">
              <input type="text" placeholder="Escreva um comentário..." data-comment-input value="${this._esc(commentText)}" style="border:none;background:var(--bg-input);flex:1" />
              <button class="btn btn-primary btn-sm" data-submit-comment ${!commentText.trim() || isSubmitting ? 'disabled' : ''}>
                ${isSubmitting ? '...' : 'Enviar'}
              </button>
            </div>
          </div>
        </div>

        <div data-comments>
          ${comments.length > 0
            ? comments.map((c, i) => `<div data-comment-slot="${i}"></div>`).join('')
            : '<div class="text-center text-muted" style="padding:24px">Nenhum comentário ainda</div>'
          }
        </div>
      </div>
    `;
  }

  updated() {
    this._renderPostCard();
    this._renderComments();
  }

  _renderPostCard() {
    const slot = this.container?.querySelector('[data-post-card]');
    if (!slot) return;
    if (this._postCard) this._postCard.destroy();

    const post = postStore.get('currentPost');
    if (!post) return;

    this._postCard = new PostCard({
      container: slot,
      props: {
        post,
        onLike: (postId) => this._handleLike(postId),
        onComment: () => {},
        onRepost: (postId) => this._handleRepost(postId),
        onShare: (postId) => this._handleShare(postId),
      },
    });
    this._postCard.mount(slot);
  }

  _renderComments() {
    for (const inst of this._commentInstances) inst.destroy();
    this._commentInstances = [];

    const parent = this.container?.querySelector('[data-comments]');
    if (!parent) return;

    this.state.comments.forEach((comment, idx) => {
      const slot = parent.querySelector(`[data-comment-slot="${idx}"]`);
      if (!slot) return;
      const inst = new CommentItem({
        container: slot,
        props: { comment },
      });
      inst.mount(slot);
      this._commentInstances.push(inst);
    });
  }

  events() {
    return {
      'input [data-comment-input]': '_handleCommentInput',
      'click [data-submit-comment]': '_handleSubmitComment',
      'keydown [data-comment-input]': '_handleCommentKeydown',
    };
  }

  _getInitials(name) {
    if (!name) return '?';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  _esc(str) {
    if (!str) return '';
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  _handleCommentInput(e) {
    this.state.commentText = e.target.value;
  }

  _handleCommentKeydown(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      this._handleSubmitComment();
    }
  }

  async _handleSubmitComment() {
    const content = this.state.commentText.trim();
    if (!content || this.state.isSubmitting) return;

    this.state.isSubmitting = true;
    this.render();

    try {
      const result = await createComment(this.state.postId, content);
      this.state.comments = [...(this.state.comments || []), result];
      this.state.commentText = '';
    } catch {
    } finally {
      this.state.isSubmitting = false;
      this.render();
    }
  }

  async _handleLike(postId) {
    const post = postStore.get('currentPost');
    if (!post) return;
    if (post.liked) await unlikePost(postId);
    else await likePost(postId);
  }

  async _handleRepost(postId) {
    try {
      await repostPost(postId);
    } catch {}
  }

  _handleShare(postId) {
    const url = `${window.location.origin}${window.location.pathname}#/post/${postId}`;
    if (navigator.share) navigator.share({ url }).catch(() => {});
    else if (navigator.clipboard) navigator.clipboard.writeText(url);
  }

  destroy() {
    if (this.unsubPosts) this.unsubPosts();
    if (this._postCard) this._postCard.destroy();
    for (const inst of this._commentInstances) inst.destroy();
    super.destroy();
  }
}
