export const ROLES = {
  USER: 'USER',
  ADMIN: 'ADMIN',
  MODERATOR: 'MODERATOR',
};

export const ROLE_LABELS = {
  USER: 'Usuário',
  ADMIN: 'Administrador',
  MODERATOR: 'Moderador',
};

export const ROLE_HIERARCHY = {
  USER: 0,
  MODERATOR: 1,
  ADMIN: 2,
};

export const PERMISSIONS = {
  CREATE_POST: [ROLES.USER, ROLES.MODERATOR, ROLES.ADMIN],
  DELETE_POST: [ROLES.MODERATOR, ROLES.ADMIN],
  DELETE_ANY_POST: [ROLES.ADMIN],
  MANAGE_USERS: [ROLES.ADMIN],
  MANAGE_GROUPS: [ROLES.MODERATOR, ROLES.ADMIN],
  VIEW_ADMIN: [ROLES.ADMIN],
  CREATE_GROUP: [ROLES.USER, ROLES.MODERATOR, ROLES.ADMIN],
  CREATE_MENTORSHIP: [ROLES.USER, ROLES.MODERATOR, ROLES.ADMIN],
  UPLOAD_LIBRARY: [ROLES.MODERATOR, ROLES.ADMIN],
};

export function hasPermission(userRole, permission) {
  const allowed = PERMISSIONS[permission];
  if (!allowed) return false;
  return allowed.includes(userRole);
}

export function hasMinimumRole(userRole, minimumRole) {
  return ROLE_HIERARCHY[userRole] >= ROLE_HIERARCHY[minimumRole];
}
