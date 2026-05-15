import { loginApi, registerApi, logoutApi, refreshTokenApi, forgotPasswordApi, resetPasswordApi } from '../api/auth.api.js';
import { getProfileApi } from '../api/user.api.js';
import authStore, { setAuth, clearAuth, setAuthLoading, setAuthError, updateUser } from '../state/auth.store.js';
import { addErrorToast, addSuccessToast } from '../state/ui.store.js';

export async function login(email, password) {
  setAuthLoading(true);
  try {
    const data = await loginApi(email, password);
    setAuth(data.user, data.accessToken, data.refreshToken);
    addSuccessToast('Login realizado com sucesso!');
    return data;
  } catch (e) {
    setAuthError(e.message);
    addErrorToast(e.message);
    throw e;
  }
}

export async function register(name, username, email, password) {
  setAuthLoading(true);
  try {
    const data = await registerApi(name, username, email, password);
    setAuth(data.user, data.accessToken, data.refreshToken);
    addSuccessToast('Conta criada com sucesso!');
    return data;
  } catch (e) {
    setAuthError(e.message);
    addErrorToast(e.message);
    throw e;
  }
}

export async function logout() {
  try {
    await logoutApi();
  } catch {
  }
  clearAuth();
  window.location.hash = '#/login';
}

export async function refreshSession() {
  try {
    const token = authStore.get('refreshToken');
    if (!token) throw new Error('No refresh token');
    const data = await refreshTokenApi(token);
    setAuth(data.user, data.accessToken, data.refreshToken);
    return data;
  } catch {
    clearAuth();
    window.location.hash = '#/login';
  }
}

export async function loadCurrentUser() {
  try {
    const data = await getProfileApi();
    updateUser(data);
    return data;
  } catch {
    clearAuth();
    window.location.hash = '#/login';
  }
}

export async function forgotPassword(email) {
  try {
    await forgotPasswordApi(email);
    addSuccessToast('Email de recuperação enviado!');
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function resetPassword(token, password) {
  try {
    await resetPasswordApi(token, password);
    addSuccessToast('Senha redefinida com sucesso!');
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export function isAuthenticated() {
  return authStore.get('isAuthenticated');
}

export function getCurrentUser() {
  return authStore.get('user');
}

export function getAccessToken() {
  return authStore.get('accessToken');
}
