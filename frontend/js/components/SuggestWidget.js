import Component from './Component.js';
import UserCard from './UserCard.js';
import { followUser, unfollowUser, searchUsers } from '../services/user.service.js';

export default class SuggestWidget extends Component {
  constructor(options = {}) {
    super(options);
    this.state = { users: [], loading: false };
    this._userCardInstances = [];
  }

  mounted() {
    this._loadSuggestions();
  }

  async _loadSuggestions() {
    this.state.loading = true;
    try {
      const data = await searchUsers('', 0);
      const users = (data.content || data).slice(0, 3);
      this.state.users = users;
    } catch {
      this.state.users = [];
    } finally {
      this.state.loading = false;
      this.render();
    }
  }

  template() {
    const users = this.state.users || [];

    if (!users.length) return '';

    return `
      <div class="trending-widget">
        <div class="widget-header">Quem seguir</div>
        <div data-suggest-users>
          ${users.map((_, i) => `<div data-suggest-slot="${i}"></div>`).join('')}
        </div>
      </div>
    `;
  }

  updated() {
    this._renderUserCards();
  }

  _renderUserCards() {
    for (const inst of this._userCardInstances) inst.destroy();
    this._userCardInstances = [];

    const parent = this.container?.querySelector('[data-suggest-users]');
    if (!parent) return;

    const users = this.state.users || [];
    users.forEach((user, idx) => {
      const slot = parent.querySelector(`[data-suggest-slot="${idx}"]`);
      if (!slot) return;
      const card = new UserCard({
        props: { user, showFollowBtn: true },
        state: {},
      });
      card.props.onFollow = (userId) => this._handleFollow(userId, card);
      card.mount(slot);
      this._userCardInstances.push(card);
    });
  }

  async _handleFollow(userId, card) {
    const user = this.state.users.find(u => u.id === userId);
    if (!user) return;

    try {
      if (user.isFollowing) {
        await unfollowUser(userId);
        user.isFollowing = false;
      } else {
        await followUser(userId);
        user.isFollowing = true;
      }
      card.render();
    } catch {
    }
  }

  destroy() {
    for (const inst of this._userCardInstances) inst.destroy();
    this._userCardInstances = [];
    super.destroy();
  }
}
