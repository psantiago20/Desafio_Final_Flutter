import Component from './Component.js';
import TrendingWidget from './TrendingWidget.js';
import SuggestWidget from './SuggestWidget.js';

export default class RightSidebar extends Component {
  mounted() {
    this._trending = new TrendingWidget({ container: this.container?.querySelector('[data-trending]') });
    this._suggest = new SuggestWidget({ container: this.container?.querySelector('[data-suggest]') });
    this._trending.mount(this.container?.querySelector('[data-trending]'));
    this._suggest.mount(this.container?.querySelector('[data-suggest]'));
  }

  template() {
    return `
      <div data-trending></div>
      <div data-suggest></div>
    `;
  }

  destroy() {
    this._trending?.destroy();
    this._suggest?.destroy();
    super.destroy();
  }
}
