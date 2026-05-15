import Component from './Component.js';
import postStore from '../state/post.store.js';
import { loadTrending } from '../services/post.service.js';

export default class TrendingWidget extends Component {
  constructor(options = {}) {
    super(options);
    this.state = { trending: [] };
  }

  mounted() {
    this.unsub = this.subscribeTo(postStore, () => {
      const trending = postStore.get('trending');
      if (trending) this.state.trending = trending;
      this.render();
    });
    loadTrending();
  }

  template() {
    const items = this.state.trending || [];

    if (!items.length) return '';

    return `
      <div class="trending-widget">
        <div class="widget-header">Assuntos do Momento</div>
        ${items.map(item => `
          <div class="widget-item" data-hashtag="${item.hashtag || item.tag || ''}">
            <div class="widget-item-title">#${item.hashtag || item.tag || ''}</div>
            <div class="widget-item-subtitle">${item.count || item.postCount || 0} posts</div>
          </div>
        `).join('')}
      </div>
    `;
  }

  events() {
    return {
      'click [data-hashtag]': '_handleHashtagClick',
    };
  }

  _handleHashtagClick(e) {
    const tag = e.currentTarget.dataset.hashtag;
    if (tag) {
      window.location.hash = `#/explore?tag=${encodeURIComponent(tag)}`;
    }
  }

  destroy() {
    if (this.unsub) this.unsub();
    super.destroy();
  }
}
