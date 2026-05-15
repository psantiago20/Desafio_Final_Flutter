import { get, post, put, del } from './client';
import { GROUP } from '../constants/api';

export function getGroupsApi(params) {
  return get(GROUP.LIST, { params });
}

export function getGroupByIdApi(id) {
  return get(GROUP.BY_ID(id));
}

export function createGroupApi(body) {
  return post(GROUP.CREATE, { body });
}

export function updateGroupApi(id, body) {
  return put(GROUP.UPDATE(id), { body });
}

export function deleteGroupApi(id) {
  return del(GROUP.DELETE(id));
}

export function joinGroupApi(id) {
  return post(GROUP.JOIN(id));
}

export function leaveGroupApi(id) {
  return del(GROUP.LEAVE(id));
}

export function getGroupMembersApi(id, params) {
  return get(GROUP.MEMBERS(id), { params });
}

export function inviteToGroupApi(id, body) {
  return post(GROUP.INVITE(id), { body });
}

export function searchGroupsApi(params) {
  return get(GROUP.SEARCH, { params });
}
