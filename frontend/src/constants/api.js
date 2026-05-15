export const API_BASE_URL = '/api/v1';

export const AUTH = {
  LOGIN: '/auth/login',
  REGISTER: '/auth/register',
  REFRESH: '/auth/refresh',
  LOGOUT: '/auth/logout',
  FORGOT_PASSWORD: '/auth/forgot-password',
  RESET_PASSWORD: '/auth/reset-password',
};

export const USER = {
  PROFILE: '/users/profile',
  USER_BY_ID: (id) => `/users/${id}`,
  FOLLOWERS: (id) => `/users/${id}/followers`,
  FOLLOWING: (id) => `/users/${id}/following`,
  FOLLOW: (id) => `/users/${id}/follow`,
  UNFOLLOW: (id) => `/users/${id}/unfollow`,
  INTERESTS: '/users/interests',
  AVATAR: '/users/avatar',
  BANNER: '/users/banner',
  SEARCH: '/users/search',
};

export const POST = {
  LIST: '/posts',
  CREATE: '/posts',
  BY_ID: (id) => `/posts/${id}`,
  DELETE: (id) => `/posts/${id}`,
  LIKE: (id) => `/posts/${id}/like`,
  UNLIKE: (id) => `/posts/${id}/unlike`,
  REPOST: (id) => `/posts/${id}/repost`,
  COMMENTS: (id) => `/posts/${id}/comments`,
  COMMENT_CREATE: (id) => `/posts/${id}/comments`,
  TIMELINE: '/posts/timeline',
  EXPLORE: '/posts/explore',
  TRENDING: '/posts/trending',
  HASHTAG: (tag) => `/posts/hashtag/${tag}`,
  USER_POSTS: (id) => `/users/${id}/posts`,
  USER_LIKES: (id) => `/users/${id}/likes`,
  UPLOAD_IMAGE: '/posts/upload',
};

export const GROUP = {
  LIST: '/groups',
  CREATE: '/groups',
  BY_ID: (id) => `/groups/${id}`,
  UPDATE: (id) => `/groups/${id}`,
  DELETE: (id) => `/groups/${id}`,
  JOIN: (id) => `/groups/${id}/join`,
  LEAVE: (id) => `/groups/${id}/leave`,
  MEMBERS: (id) => `/groups/${id}/members`,
  INVITE: (id) => `/groups/${id}/invite`,
  SEARCH: '/groups/search',
};

export const LIBRARY = {
  LIST: '/library',
  CREATE: '/library',
  BY_ID: (id) => `/library/${id}`,
  UPDATE: (id) => `/library/${id}`,
  DELETE: (id) => `/library/${id}`,
  SEARCH: '/library/search',
  POPULAR: '/library/popular',
  DOWNLOAD: (id) => `/library/${id}/download`,
};

export const MENTORSHIP = {
  LIST: '/mentorships',
  CREATE: '/mentorships',
  BY_ID: (id) => `/mentorships/${id}`,
  UPDATE: (id) => `/mentorships/${id}`,
  DELETE: (id) => `/mentorships/${id}`,
  SESSIONS: (id) => `/mentorships/${id}/sessions`,
  SESSION_BY_ID: (mid, sid) => `/mentorships/${mid}/sessions/${sid}`,
  SESSION_FEEDBACK: (mid, sid) => `/mentorships/${mid}/sessions/${sid}/feedback`,
  AVAILABLE: '/mentorships/available',
  APPLY: (id) => `/mentorships/${id}/apply`,
};

export const GAMIFICATION = {
  STATS: '/gamification/stats',
  LEADERBOARD: '/gamification/leaderboard',
  BADGES: '/gamification/badges',
  HISTORY: '/gamification/history',
};

export const NOTIFICATION = {
  LIST: '/notifications',
  UNREAD_COUNT: '/notifications/unread-count',
  MARK_READ: (id) => `/notifications/${id}/read`,
  MARK_ALL_READ: '/notifications/read-all',
  PREFERENCES: '/notifications/preferences',
};
