import { get, post, put } from './client';
import { NOTIFICATION } from '../constants/api';

export function getNotificationsApi(params) {
  return get(NOTIFICATION.LIST, { params });
}

export function getUnreadCountApi() {
  return get(NOTIFICATION.UNREAD_COUNT);
}

export function markNotificationReadApi(id) {
  return put(NOTIFICATION.MARK_READ(id));
}

export function markAllNotificationsReadApi() {
  return put(NOTIFICATION.MARK_ALL_READ);
}

export function getNotificationPreferencesApi() {
  return get(NOTIFICATION.PREFERENCES);
}

export function updateNotificationPreferencesApi(body) {
  return put(NOTIFICATION.PREFERENCES, { body });
}
