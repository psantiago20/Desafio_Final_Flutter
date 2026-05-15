import Component from './Component.js';

export default class InfiniteScroll extends Component {
  constructor(options = {}) {
    super(options);
    this._observer = null;
    this._loading = false;
    this._disabled = false;
  }

  template() {
    return '';
  }

  mounted() {
    const sentinel = this.props.sentinel || this.container?.querySelector('[data-scroll-sentinel]');
    if (sentinel) {
      this._setupObserver(sentinel);
    }
  }

  _setupObserver(sentinel) {
    this._observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && !this._loading && !this._disabled) {
          this._loading = true;
          const result = this.props.onLoad?.();
          if (result && typeof result.finally === 'function') {
            result.finally(() => { this._loading = false; });
          } else {
            this._loading = false;
          }
        }
      },
      { rootMargin: this.props.rootMargin || '200px', threshold: 0 }
    );
    this._observer.observe(sentinel);
  }

  observe(sentinel) {
    if (this._observer) this._observer.disconnect();
    if (sentinel) this._setupObserver(sentinel);
  }

  setLoading(l) {
    this._loading = l;
  }

  setDisabled(d) {
    this._disabled = d;
  }

  destroy() {
    if (this._observer) {
      this._observer.disconnect();
      this._observer = null;
    }
    super.destroy();
  }
}
