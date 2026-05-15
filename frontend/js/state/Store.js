export default class Store {
  constructor(initialState = {}, options = {}) {
    this._state = { ...initialState };
    this._initialState = { ...initialState };
    this._subscribers = new Set();
    this._persistKey = options.persistKey || null;
    this._persistFields = options.persistFields || [];

    if (this._persistKey) {
      this._loadPersistedState();
    }
  }

  get state() {
    return this._state;
  }

  get(field) {
    return this._state[field];
  }

  set(update) {
    const prevState = { ...this._state };
    if (typeof update === 'function') {
      this._state = { ...this._state, ...update(this._state) };
    } else {
      this._state = { ...this._state, ...update };
    }
    this._notify(prevState);
    if (this._persistKey) {
      this._persistState();
    }
  }

  subscribe(fn) {
    this._subscribers.add(fn);
    return () => this._subscribers.delete(fn);
  }

  _notify(prevState) {
    for (const fn of this._subscribers) {
      try {
        fn(this._state, prevState);
      } catch (e) {
        console.error('Store subscriber error:', e);
      }
    }
  }

  reset() {
    const prevState = { ...this._state };
    this._state = { ...this._initialState };
    this._notify(prevState);
    if (this._persistKey) {
      localStorage.removeItem(this._persistKey);
    }
  }

  _loadPersistedState() {
    try {
      const saved = localStorage.getItem(this._persistKey);
      if (saved) {
        const parsed = JSON.parse(saved);
        for (const field of this._persistFields) {
          if (field in parsed) {
            this._state[field] = parsed[field];
          }
        }
      }
    } catch {
    }
  }

  _persistState() {
    try {
      const toSave = {};
      for (const field of this._persistFields) {
        if (field in this._state) {
          toSave[field] = this._state[field];
        }
      }
      localStorage.setItem(this._persistKey, JSON.stringify(toSave));
    } catch {
    }
  }
}
