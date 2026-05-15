import Component from '../components/Component.js';
import Feed from '../components/Feed.js';
import InfiniteScroll from '../components/InfiniteScroll.js';
import postStore from '../state/post.store.js';
import { loadExplore, loadTrending, likePost, unlikePost } from '../services/post.service.js';

export default class ExplorePage extends Component {
  constructor(options = {}) {
    super(options);
    this.state = {
      page: 0,
      hasMore: true,
      searchQuery: '',
    };
  }

  mounted() {
    this.unsubPosts = this.subscribeTo(postStore, () => this.render());
    loadTrending();
    this._loadPosts();
  }

  template() {
    const { explore = [], isLoading, error } = postStore.state;
    const trending = postStore.get('trending') || [];

    return `
      <div class="explore-page">
        <div class="page-header">
          <h2 class="page-title">Explorar</h2>
          <div class="search-bar mt-sm">
            <span class="search-icon">🔍</span>
            <input type="search" placeholder="Buscar posts..." data-search-input value="${this.state.searchQuery}" />
          </div>
        </div>

        ${trending.length > 0 ? `
          <div style="padding:var(--spacing-sm) var(--spacing-lg);display:flex;gap:8px;flex-wrap:wrap;border-bottom:1px solid var(--border-primary)">
            ${trending.slice(0, 8).map(t => `
              <span class="chip" data-trend-tag="${t.hashtag || t.tag || ''}">#${t.hashtag || t.tag || ''}</span>
            `).join('')}
          </div>
        ` : ''}

        <div data-feed-container></div>
        <div data-scroll-sentinel></div>
      </div>
    `;
  }

  updated() {
    this._renderFeed();
    this._setupInfiniteScroll();
  }

  _renderFeed() {
    const container = this.container?.querySelector('[data-feed-container]');
    if (!container) return;
    if (this._feed) this._feed.destroy();

    const { explore, isLoading, error } = postStore.state;
    const pagination = postStore.get('pagination') || {};
    this.state.hasMore = pagination.hasMore !== false;

    this._feed = new Feed({
      container,
      state: {
        posts: explore,
        isLoading,
        error,
        hasMore: this.state.hasMore,
      },
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

  _loadPosts() {
    this.state.page = 0;
    loadExplore(0).catch(() => {});
  }

  async _loadMore() {
    if (!this.state.hasMore) return;
    this.state.page++;
    try {
      const data = await loadExplore(this.state.page);
      this.state.hasMore = !data.last;
    } catch {
      this.state.page--;
    }
  }

  async _handleLike(postId) {
    const posts = postStore.get('explore');
    const post = posts.find(p => p.id === postId);
    if (!post) return;
    if (post.liked) {
      await unlikePost(postId);
    } else {
      await likePost(postId);
    }
  }

  events() {
    return {
      'click [data-trend-tag]': '_handleTrendClick',
      'input [data-search-input]': '_handleSearch',
    };
  }

  _handleTrendClick(e) {
    const tag = e.currentTarget.dataset.trendTag;
    if (tag) {
      this.state.searchQuery = tag;
      window.location.hash = `#/explore?tag=${encodeURIComponent(tag)}`;
    }
  }

  _handleSearch(e) {
    this.state.searchQuery = e.target.value;
  }

  destroy() {
    if (this.unsubPosts) this.unsubPosts();
    if (this._feed) this._feed.destroy();
    if (this._scroll) this._scroll.destroy();
    super.destroy();
  }
}
