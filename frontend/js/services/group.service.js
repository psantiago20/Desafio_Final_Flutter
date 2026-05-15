import {
  getGroupsApi, getGroupByIdApi, createGroupApi,
  updateGroupApi, deleteGroupApi, joinGroupApi,
  leaveGroupApi, getGroupMembersApi, inviteToGroupApi,
  searchGroupsApi,
} from '../api/group.api.js';
import { addErrorToast, addSuccessToast } from '../state/ui.store.js';

export async function loadGroups(page = 0, size = 20) {
  try {
    return await getGroupsApi(page, size);
  } catch (e) {
    addErrorToast('Erro ao carregar grupos');
    throw e;
  }
}

export async function loadGroupDetail(groupId) {
  try {
    return await getGroupByIdApi(groupId);
  } catch (e) {
    addErrorToast('Erro ao carregar grupo');
    throw e;
  }
}

export async function createGroup(data) {
  try {
    const result = await createGroupApi(data);
    addSuccessToast('Grupo criado!');
    return result;
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function updateGroup(id, data) {
  try {
    const result = await updateGroupApi(id, data);
    addSuccessToast('Grupo atualizado!');
    return result;
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function deleteGroup(id) {
  try {
    await deleteGroupApi(id);
    addSuccessToast('Grupo excluído');
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function joinGroup(id) {
  try {
    await joinGroupApi(id);
    addSuccessToast('Você entrou no grupo!');
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function leaveGroup(id) {
  try {
    await leaveGroupApi(id);
    addSuccessToast('Você saiu do grupo');
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function loadGroupMembers(id, page = 0) {
  try {
    return await getGroupMembersApi(id, page);
  } catch (e) {
    addErrorToast('Erro ao carregar membros');
    throw e;
  }
}

export async function inviteMember(groupId, userId) {
  try {
    await inviteToGroupApi(groupId, userId);
    addSuccessToast('Convite enviado!');
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function searchGroups(query, page = 0) {
  try {
    return await searchGroupsApi(query, page);
  } catch (e) {
    addErrorToast('Erro na busca');
    throw e;
  }
}
