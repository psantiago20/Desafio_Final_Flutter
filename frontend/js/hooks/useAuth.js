import authStore from '../state/auth.store.js';
import { setAuth, clearAuth, setAuthLoading, setAuthError, setTokens, updateUser } from '../state/auth.store.js';
import { login, register, logout, refreshSession, loadCurrentUser, isAuthenticated, getCurrentUser, getAccessToken } from '../services/auth.service.js';

export function useAuth() {
  return {
    user: authStore.get('user'),
    isAuthenticated: authStore.get('isAuthenticated'),
    isLoading: authStore.get('isLoading'),
    error: authStore.get('error'),
    login,
    register,
    logout,
    refreshSession,
    loadCurrentUser,
    isAuthenticated: () => isAuthenticated(),
    getUser: () => getCurrentUser(),
    getToken: () => getAccessToken(),
    updateUser,
    setTokens,
    clearAuth,
    setAuthLoading,
    setAuth,
    setAuthError,
  };
}

export default useAuth;
