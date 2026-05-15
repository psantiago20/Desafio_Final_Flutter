import { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { configureAuth } from '../api/client';
import * as authApi from '../api/auth.api';
import * as userApi from '../api/user.api';
import { AUTH_STORAGE_KEY } from '../constants/config';

const AuthContext = createContext(null);

function loadPersistedAuth() {
  try {
    const saved = localStorage.getItem(AUTH_STORAGE_KEY);
    if (saved) return JSON.parse(saved);
  } catch {}
  return null;
}

function persistAuth(data) {
  try {
    localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(data));
  } catch {}
}

function clearPersistedAuth() {
  try {
    localStorage.removeItem(AUTH_STORAGE_KEY);
  } catch {}
}

export function AuthProvider({ children }) {
  const persisted = loadPersistedAuth();
  const [user, setUser] = useState(persisted?.user || null);
  const [accessToken, setAccessToken] = useState(persisted?.accessToken || null);
  const [refreshToken, setRefreshToken] = useState(persisted?.refreshToken || null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  const isAuthenticated = !!accessToken;

  const persist = useCallback((u, at, rt) => {
    setUser(u);
    setAccessToken(at);
    setRefreshToken(rt);
    if (u || at || rt) {
      persistAuth({ user: u, accessToken: at, refreshToken: rt });
    } else {
      clearPersistedAuth();
    }
  }, []);

  const login = useCallback(async (email, password) => {
    setError(null);
    setIsLoading(true);
    try {
      const data = await authApi.loginApi(email, password);
      persist(data.user, data.accessToken, data.refreshToken);
      return data;
    } catch (e) {
      setError(e.message);
      throw e;
    } finally {
      setIsLoading(false);
    }
  }, [persist]);

  const register = useCallback(async (name, username, email, password) => {
    setError(null);
    setIsLoading(true);
    try {
      const data = await authApi.registerApi(name, username, email, password);
      persist(data.user, data.accessToken, data.refreshToken);
      return data;
    } catch (e) {
      setError(e.message);
      throw e;
    } finally {
      setIsLoading(false);
    }
  }, [persist]);

  const logout = useCallback(async () => {
    try {
      await authApi.logoutApi();
    } catch {}
    persist(null, null, null);
  }, [persist]);

  const setTokens = useCallback((at, rt) => {
    setAccessToken(at);
    setRefreshToken(rt);
    persist(user, at, rt);
  }, [persist, user]);

  const updateUser = useCallback((updates) => {
    setUser(prev => ({ ...prev, ...updates }));
    persist({ ...user, ...updates }, accessToken, refreshToken);
  }, [persist, user, accessToken, refreshToken]);

  useEffect(() => {
    configureAuth({
      getToken: () => accessToken,
      setTokens,
      clearAuth: () => persist(null, null, null),
      onUnauthorized: () => {},
    });
  }, [accessToken, setTokens, persist]);

  useEffect(() => {
    async function bootstrap() {
      if (accessToken && refreshToken) {
        try {
          const data = await authApi.refreshTokenApi(refreshToken);
          persist(data.user, data.accessToken, data.refreshToken);
        } catch {
          persist(null, null, null);
        }
      }
      setIsLoading(false);
    }
    bootstrap();
  }, []);

  return (
    <AuthContext.Provider value={{
      user, accessToken, isAuthenticated,
      isLoading, error,
      login, register, logout, setTokens, updateUser, setError,
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
