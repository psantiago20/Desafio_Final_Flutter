import Component from './Component.js';
import PostCard from './PostCard.js';
import LoadingSpinner from './LoadingSpinner.js';

export default class Feed extends Component {
  constructor(options = {}) {
    super(options);
    this._postCardInstances = [];
  }

  template() {
    const { posts = [], isLoading = false, error = null, hasMore = true } = this.state;

    if (isLoading && posts.length === 0) {
      return `<div class="loading-container"><div class="spinner spinner-lg"></div></div>`;
    }

    if (error && posts.length === 0) {
      return `
        <div class="feed-error">
          <p>${error}</p>
          <button class="btn btn-secondary btn-sm mt-md" data-retry>Tentar novamente</button>
        </div>
      `;
    }

    if (!isLoading && posts.length === 0) {
      return `
        <div class="empty-state">
          <div class="empty-state-icon">📭</div>
          <div class="empty-state-text">Nenhum post encontrado</div>
          <p class="text-muted mt-sm">Siga outros usuários para ver posts aqui</p>
        </div>
      `;
    }

    return `
      <div class="feed-posts" data-feed-posts>
        ${posts.map((post, idx) => `<div data-post-slot="${idx}"></div>`).join('')}
      </div>
      ${isLoading ? '<div class="loading-inline"><div class="spinner"></div></div>' : ''}
      ${!hasMore && posts.length > 0 ? '<div class="text-center text-muted py-md" style="padding:16px">Você viu tudo!</div>' : ''}
    `;
  }

  mounted() {
    this._renderPosts();
  }

  updated() {
    this._renderPosts();
  }

  _renderPosts() {
    const slotParent = this.container?.querySelector('[data-feed-posts]');
    if (!slotParent) return;
    for (const inst of this._postCardInstances) {
      inst.destroy();
    }
    this._postCardInstances = [];

    const posts = this.state.posts || [];
    posts.forEach((post, idx) => {
      const slot = slotParent.querySelector(`[data-post-slot="${idx}"]`);
      if (!slot) return;
      const card = new PostCard({
        props: { post },
        state: { ...this.props },
      });
      card.props = { ...this.props, post };
      card.mount(slot);
      this._postCardInstances.push(card);
    });
  }

  destroy() {
    for (const inst of this._postCardInstances) {
      inst.destroy();
    }
    this._postCardInstances = [];
    super.destroy();
  }
}
