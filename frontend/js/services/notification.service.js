import {
  getNotificationsApi, getUnreadCountApi,
  markNotificationReadApi, markAllNotificationsReadApi,
  getNotificationPreferencesApi, updateNotificationPreferencesApi,
} from '../api/notification.api.js';
import { addErrorToast } from '../state/ui.store.js';

export async function loadNotifications(page = 0, size = 20) {
  try {
    return await getNotificationsApi(page, size);
  } catch (e) {
    addErrorToast('Erro ao carregar notificações');
    throw e;
  }
}

export async function loadUnreadCount() {
  try {
    return await getUnreadCountApi();
  } catch {
    return { count: 0 };
  }
}

export async function markAsRead(id) {
  try {
    await markNotificationReadApi(id);
  } catch {
  }
}

export async function markAllAsRead() {
  try {
    await markAllNotificationsReadApi();
  } catch {
  }
}

export async function loadNotificationPreferences() {
  try {
    return await getNotificationPreferencesApi();
  } catch {
    return {};
  }
}

export async function updateNotificationPreferences(preferences) {
  try {
    return await updateNotificationPreferencesApi(preferences);
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}
