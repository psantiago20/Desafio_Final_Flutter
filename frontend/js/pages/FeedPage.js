import Component from '../components/Component.js';
import PostComposer from '../components/PostComposer.js';
import Feed from '../components/Feed.js';
import InfiniteScroll from '../components/InfiniteScroll.js';
import postStore from '../state/post.store.js';
import authStore from '../state/auth.store.js';
import { loadTimeline, createPost, likePost, unlikePost, repostPost, uploadPostImage } from '../services/post.service.js';

export default class FeedPage extends Component {
  constructor(options = {}) {
    super(options);
    this.state = {
      page: 0,
      hasMore: true,
    };
  }

  mounted() {
    this.unsubPosts = this.subscribeTo(postStore, () => this.render());
    this._loadPosts();

    this._composer = new PostComposer({
      container: this.container?.querySelector('[data-composer]'),
      props: {
        onSubmit: (data) => this._handleCreatePost(data),
      },
    });
    this._composer.mount(this.container?.querySelector('[data-composer]'));
  }

  template() {
    const { posts = [], isLoading, error } = postStore.state;
    const { hasMore } = this.state;

    return `
      <div class="feed-page">
        <div class="page-header">
          <div class="timeline-header">
            <h2 class="page-title">Feed</h2>
          </div>
        </div>
        <div data-composer></div>
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

    const { posts, isLoading, error } = postStore.state;
    const pagination = postStore.get('pagination') || {};
    this.state.hasMore = pagination.hasMore !== false;

    this._feed = new Feed({
      container,
      state: {
        posts,
        isLoading,
        error,
        hasMore: this.state.hasMore,
      },
      props: {
        onLike: (postId) => this._handleLike(postId),
        onComment: (postId) => { window.location.hash = `#/post/${postId}`; },
        onRepost: (postId) => this._handleRepost(postId),
        onShare: (postId) => this._handleShare(postId),
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
    loadTimeline(0).catch(() => {});
  }

  async _loadMore() {
    if (!this.state.hasMore) return;
    this.state.page++;
    try {
      const data = await loadTimeline(this.state.page);
      this.state.hasMore = !data.last;
    } catch {
      this.state.page--;
    }
  }

  async _handleCreatePost(data) {
    const payload = { content: data.content, visibility: data.visibility };
    if (data.imageFile) {
      const uploadResult = await uploadPostImage(data.imageFile);
      payload.imageUrl = uploadResult.url || uploadResult.imageUrl;
    }
    await createPost(payload);
  }

  async _handleLike(postId) {
    const posts = postStore.get('posts');
    const post = posts.find(p => p.id === postId);
    if (!post) return;
    if (post.liked) {
      await unlikePost(postId);
    } else {
      await likePost(postId);
    }
  }

  async _handleRepost(postId) {
    try {
      await repostPost(postId);
    } catch {}
  }

  _handleShare(postId) {
    const url = `${window.location.origin}${window.location.pathname}#/post/${postId}`;
    if (navigator.share) {
      navigator.share({ url }).catch(() => {});
    } else if (navigator.clipboard) {
      navigator.clipboard.writeText(url);
    }
  }

  destroy() {
    if (this.unsubPosts) this.unsubPosts();
    if (this._composer) this._composer.destroy();
    if (this._feed) this._feed.destroy();
    if (this._scroll) this._scroll.destroy();
    super.destroy();
  }
}
