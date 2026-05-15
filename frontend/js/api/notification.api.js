import { get, put } from './client.js';
import { NOTIFICATION } from '../constants/api.js';

export function getNotificationsApi(page = 0, size = 20) {
  return get(NOTIFICATION.LIST, { params: { page, size } });
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

export function updateNotificationPreferencesApi(preferences) {
  return put(NOTIFICATION.PREFERENCES, { body: preferences });
}
