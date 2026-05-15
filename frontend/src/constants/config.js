export const APP_NAME = 'Pitaya';
export const APP_DESCRIPTION = 'Rede Social Acadêmica';

export const PAGINATION_SIZE = 20;
export const MAX_POST_LENGTH = 500;
export const MAX_COMMENT_LENGTH = 300;
export const MAX_GROUP_NAME_LENGTH = 100;
export const MAX_BIO_LENGTH = 500;
export const MAX_USERNAME_LENGTH = 30;

export const THEME_STORAGE_KEY = 'pitaya-theme';
export const AUTH_STORAGE_KEY = 'pitaya-auth';
export const USER_STORAGE_KEY = 'pitaya-user';

export const TOAST_DURATION = 4000;
export const TOAST_ERROR_DURATION = 6000;

export const IMAGE_MAX_SIZE = 5 * 1024 * 1024;
export const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

export const DEBOUNCE_DELAY = 300;
export const INFINITE_SCROLL_THRESHOLD = 200;

export const ROLES = {
  USER: 'USER',
  ADMIN: 'ADMIN',
  MODERATOR: 'MODERATOR',
};

export const VISIBILITY = {
  PUBLIC: 'PUBLIC',
  FOLLOWERS: 'FOLLOWERS',
  PRIVATE: 'PRIVATE',
};

export const MENTORSHIP_STATUS = {
  PENDING: 'PENDING',
  ACTIVE: 'ACTIVE',
  COMPLETED: 'COMPLETED',
  CANCELLED: 'CANCELLED',
};

export const NOTIFICATION_TYPES = {
  LIKE: 'LIKE',
  COMMENT: 'COMMENT',
  FOLLOW: 'FOLLOW',
  MENTORSHIP: 'MENTORSHIP',
  GROUP_INVITE: 'GROUP_INVITE',
  SYSTEM: 'SYSTEM',
};
