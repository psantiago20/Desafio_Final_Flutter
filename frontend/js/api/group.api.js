import { get, post, put, del } from './client.js';
import { GROUP } from '../constants/api.js';

export function getGroupsApi(page = 0, size = 20) {
  return get(GROUP.LIST, { params: { page, size } });
}

export function getGroupByIdApi(id) {
  return get(GROUP.BY_ID(id));
}

export function createGroupApi(data) {
  return post(GROUP.CREATE, { body: data });
}

export function updateGroupApi(id, data) {
  return put(GROUP.UPDATE(id), { body: data });
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

export function getGroupMembersApi(id, page = 0, size = 20) {
  return get(GROUP.MEMBERS(id), { params: { page, size } });
}

export function inviteToGroupApi(groupId, userId) {
  return post(GROUP.INVITE(groupId), { body: { userId } });
}

export function searchGroupsApi(query, page = 0, size = 20) {
  return get(GROUP.SEARCH, { params: { query, page, size } });
}
