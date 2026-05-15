export default class Component {
  constructor(options = {}) {
    this.container = options.container || null;
    this.state = options.state || {};
    this.props = options.props || {};
    this._subscriptions = [];
    this._eventHandlers = [];
    this._mounted = false;
    this._destroyed = false;
  }

  beforeMount() {}
  mounted() {}
  beforeUpdate() {}
  updated() {}
  beforeDestroy() {}
  destroyed() {}

  template() {
    return '';
  }

  mount(container) {
    if (!container) return;
    this.container = container;
    this.beforeMount();
    this.render();
    this._mounted = true;
    this.mounted();
  }

  render() {
    if (!this.container) return;
    this.beforeUpdate();
    this.unbindEvents();
    this.container.innerHTML = this.template();
    this.bindEvents();
    this.updated();
  }

  setState(newState) {
    if (this._destroyed) return;
    const prev = { ...this.state };
    if (typeof newState === 'function') {
      this.state = { ...this.state, ...newState(this.state) };
    } else {
      this.state = { ...this.state, ...newState };
    }
    this.render();
  }

  events() {
    return {};
  }

  bindEvents() {
    const eventMap = this.events();
    for (const [key, handler] of Object.entries(eventMap)) {
      const [event, ...selectorParts] = key.trim().split(/\s+/);
      const selector = selectorParts.join(' ');
      if (selector && this.container) {
        const cb = (e) => {
          const target = e.target.closest(selector);
          if (target && this.container.contains(target)) {
            handler.call(this, e, target);
          }
        };
        this.container.addEventListener(event, cb);
        this._eventHandlers.push({ event, cb });
      } else if (this.container) {
        const cb = (e) => handler.call(this, e);
        this.container.addEventListener(event, cb);
        this._eventHandlers.push({ event, cb });
      }
    }
  }

  unbindEvents() {
    for (const { event, cb } of this._eventHandlers) {
      this.container?.removeEventListener(event, cb);
    }
    this._eventHandlers = [];
  }

  subscribeTo(store, callback) {
    const unsub = store.subscribe(callback);
    this._subscriptions.push(unsub);
    return unsub;
  }

  destroy() {
    if (this._destroyed) return;
    this.beforeDestroy();
    this.unbindEvents();
    for (const unsub of this._subscriptions) {
      unsub();
    }
    this._subscriptions = [];
    if (this.container) {
      this.container.innerHTML = '';
    }
    this._mounted = false;
    this._destroyed = true;
    this.destroyed();
  }
}
