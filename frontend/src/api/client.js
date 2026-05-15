import { API_BASE_URL } from '../constants/api';

export class ApiError extends Error {
  constructor(message, status, data) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.data = data;
  }
}

let isRefreshing = false;
let refreshQueue = [];
let getAccessToken;
let setTokensFn;
let clearAuthFn;
let onUnauthorized;

export function configureAuth({ getToken, setTokens, clearAuth, onUnauth }) {
  getAccessToken = getToken;
  setTokensFn = setTokens;
  clearAuthFn = clearAuth;
  onUnauthorized = onUnauth;
}

async function refreshToken() {
  const refreshTokenVal = getAccessToken('refreshToken');
  if (!refreshTokenVal) throw new ApiError('No refresh token', 401);
  const response = await fetch(`${API_BASE_URL}/auth/refresh`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken: refreshTokenVal }),
  });
  if (!response.ok) throw new ApiError('Failed to refresh token', response.status);
  const data = await response.json();
  setTokensFn(data.accessToken, data.refreshToken);
  return data.accessToken;
}

async function handleRefresh() {
  if (isRefreshing) {
    return new Promise((resolve, reject) => {
      refreshQueue.push({ resolve, reject });
    });
  }
  isRefreshing = true;
  try {
    const token = await refreshToken();
    refreshQueue.forEach(q => q.resolve(token));
    return token;
  } catch (e) {
    refreshQueue.forEach(q => q.reject(e));
    clearAuthFn();
    onUnauthorized();
    throw e;
  } finally {
    refreshQueue = [];
    isRefreshing = false;
  }
}

export async function request(method, path, options = {}) {
  const { body, params, headers: customHeaders, formData } = options;

  let url = `${API_BASE_URL}${path}`;
  if (params) {
    const searchParams = new URLSearchParams();
    for (const [key, value] of Object.entries(params)) {
      if (value !== undefined && value !== null) {
        searchParams.append(key, value);
      }
    }
    const qs = searchParams.toString();
    if (qs) url += `?${qs}`;
  }

  const headers = { ...customHeaders };
  const token = getAccessToken();
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  let fetchBody;
  if (formData) {
    fetchBody = formData;
  } else if (body) {
    headers['Content-Type'] = 'application/json';
    fetchBody = JSON.stringify(body);
  }

  let response;
  try {
    response = await fetch(url, {
      method,
      headers,
      body: fetchBody,
    });
  } catch (e) {
    throw new ApiError('Erro de conexão', 0, e);
  }

  if (response.status === 401 && token) {
    try {
      const newToken = await handleRefresh();
      headers['Authorization'] = `Bearer ${newToken}`;
      response = await fetch(url, {
        method,
        headers,
        body: fetchBody,
      });
    } catch {
      throw new ApiError('Sessão expirada', 401);
    }
  }

  let data;
  const contentType = response.headers.get('content-type');
  if (contentType && contentType.includes('application/json')) {
    data = await response.json();
  } else {
    data = await response.text();
  }

  if (!response.ok) {
    const message = data?.message || data?.error || `Erro ${response.status}`;
    throw new ApiError(message, response.status, data);
  }

  return data;
}

export const get = (path, options) => request('GET', path, options);
export const post = (path, options) => request('POST', path, options);
export const put = (path, options) => request('PUT', path, options);
export const del = (path, options) => request('DELETE', path, options);
export const upload = (path, formData, options) => request('POST', path, { ...options, formData });
