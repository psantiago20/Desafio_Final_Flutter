import { get, post, put } from './client.js';
import { AUTH } from '../constants/api.js';

export function loginApi(email, password) {
  return post(AUTH.LOGIN, { body: { email, password } });
}

export function registerApi(name, username, email, password) {
  return post(AUTH.REGISTER, { body: { name, username, email, password } });
}

export function refreshTokenApi(refreshToken) {
  return post(AUTH.REFRESH, { body: { refreshToken } });
}

export function logoutApi() {
  return post(AUTH.LOGOUT);
}

export function forgotPasswordApi(email) {
  return post(AUTH.FORGOT_PASSWORD, { body: { email } });
}

export function resetPasswordApi(token, password) {
  return post(AUTH.RESET_PASSWORD, { body: { token, password } });
}
