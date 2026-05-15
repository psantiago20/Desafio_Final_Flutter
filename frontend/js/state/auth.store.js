import Store from './Store.js';

const initialState = {
  user: null,
  accessToken: null,
  refreshToken: null,
  isAuthenticated: false,
  isLoading: true,
  error: null,
};

const authStore = new Store(initialState, {
  persistKey: 'pitaya-auth',
  persistFields: ['accessToken', 'refreshToken', 'user', 'isAuthenticated'],
});

export function setAuth(user, accessToken, refreshToken) {
  authStore.set({
    user,
    accessToken,
    refreshToken,
    isAuthenticated: true,
    isLoading: false,
    error: null,
  });
}

export function clearAuth() {
  authStore.set({
    user: null,
    accessToken: null,
    refreshToken: null,
    isAuthenticated: false,
    isLoading: false,
    error: null,
  });
}

export function setAuthLoading(loading) {
  authStore.set({ isLoading: loading });
}

export function setAuthError(error) {
  authStore.set({ error, isLoading: false });
}

export function updateUser(user) {
  const current = authStore.get('user');
  authStore.set({ user: { ...current, ...user } });
}

export function setTokens(accessToken, refreshToken) {
  authStore.set({ accessToken, refreshToken });
}

export default authStore;
