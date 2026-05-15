import Store from './Store.js';

const initialState = {
  theme: 'light',
  sidebarOpen: true,
  activeTab: 'feed',
  modals: [],
  toasts: [],
  currentRoute: '',
  isMobile: window.innerWidth < 768,
  showMobileNav: false,
};

const uiStore = new Store(initialState, {
  persistKey: 'pitaya-ui',
  persistFields: ['theme'],
});

export function setTheme(theme) {
  uiStore.set({ theme });
  document.documentElement.setAttribute('data-theme', theme);
}

export function toggleTheme() {
  const current = uiStore.get('theme');
  const next = current === 'light' ? 'dark' : 'light';
  setTheme(next);
}

export function setSidebarOpen(open) {
  uiStore.set({ sidebarOpen: open });
}

export function setActiveTab(tab) {
  uiStore.set({ activeTab: tab });
}

export function showModal(modal) {
  const modals = uiStore.get('modals');
  uiStore.set({ modals: [...modals, { id: Date.now(), ...modal }] });
}

export function closeModal(id) {
  const modals = uiStore.get('modals').filter(m => m.id !== id);
  uiStore.set({ modals });
}

export function closeTopModal() {
  const modals = uiStore.get('modals').slice(0, -1);
  uiStore.set({ modals });
}

export function addToast(toast) {
  const toasts = uiStore.get('toasts');
  const id = Date.now();
  uiStore.set({ toasts: [...toasts, { id, ...toast }] });
  setTimeout(() => removeToast(id), toast.duration || 4000);
  return id;
}

export function addSuccessToast(message) {
  return addToast({ type: 'success', message, duration: 4000 });
}

export function addErrorToast(message) {
  return addToast({ type: 'error', message, duration: 6000 });
}

export function removeToast(id) {
  const toasts = uiStore.get('toasts').filter(t => t.id !== id);
  uiStore.set({ toasts });
}

export function setCurrentRoute(route) {
  uiStore.set({ currentRoute: route });
}

export function setIsMobile(isMobile) {
  uiStore.set({ isMobile });
}

export function setShowMobileNav(show) {
  uiStore.set({ showMobileNav: show });
}

export default uiStore;
