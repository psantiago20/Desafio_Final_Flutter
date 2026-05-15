import {
  getProfileApi, getUserByIdApi, updateProfileApi,
  getFollowersApi, getFollowingApi, followUserApi, unfollowUserApi,
  getInterestsApi, updateInterestsApi,
  uploadAvatarApi, uploadBannerApi, searchUsersApi,
} from '../api/user.api.js';
import { setProfile, setFollowers, setFollowing, setInterests, setUserLoading } from '../state/user.store.js';
import { updateUser } from '../state/auth.store.js';
import { addErrorToast, addSuccessToast } from '../state/ui.store.js';

export async function loadProfile() {
  setUserLoading(true);
  try {
    const data = await getProfileApi();
    setProfile(data);
    updateUser(data);
    return data;
  } catch (e) {
    addErrorToast('Erro ao carregar perfil');
    throw e;
  }
}

export async function loadUserProfile(userId) {
  setUserLoading(true);
  try {
    const data = await getUserByIdApi(userId);
    setProfile(data);
    return data;
  } catch (e) {
    addErrorToast('Erro ao carregar perfil');
    throw e;
  }
}

export async function updateProfile(data) {
  try {
    const result = await updateProfileApi(data);
    updateUser(result);
    addSuccessToast('Perfil atualizado!');
    return result;
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function loadFollowers(userId, page = 0) {
  try {
    const data = await getFollowersApi(userId, page);
    setFollowers(data.content || []);
    return data;
  } catch (e) {
    addErrorToast('Erro ao carregar seguidores');
    throw e;
  }
}

export async function loadFollowing(userId, page = 0) {
  try {
    const data = await getFollowingApi(userId, page);
    setFollowing(data.content || []);
    return data;
  } catch (e) {
    addErrorToast('Erro ao carregar seguindo');
    throw e;
  }
}

export async function followUser(userId) {
  try {
    await followUserApi(userId);
    addSuccessToast('Usuário seguido!');
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function unfollowUser(userId) {
  try {
    await unfollowUserApi(userId);
    addSuccessToast('Deixou de seguir');
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function loadInterests() {
  try {
    const data = await getInterestsApi();
    setInterests(data.interests || []);
    return data;
  } catch {
    return [];
  }
}

export async function saveInterests(interests) {
  try {
    await updateInterestsApi(interests);
    setInterests(interests);
    addSuccessToast('Interesses atualizados!');
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function uploadAvatar(file) {
  const formData = new FormData();
  formData.append('file', file);
  try {
    const data = await uploadAvatarApi(formData);
    updateUser({ avatarUrl: data.url });
    addSuccessToast('Avatar atualizado!');
    return data;
  } catch (e) {
    addErrorToast('Erro ao enviar avatar');
    throw e;
  }
}

export async function uploadBanner(file) {
  const formData = new FormData();
  formData.append('file', file);
  try {
    const data = await uploadBannerApi(formData);
    updateUser({ bannerUrl: data.url });
    addSuccessToast('Banner atualizado!');
    return data;
  } catch (e) {
    addErrorToast('Erro ao enviar banner');
    throw e;
  }
}

export async function searchUsers(query, page = 0) {
  try {
    return await searchUsersApi(query, page);
  } catch (e) {
    addErrorToast('Erro na busca');
    throw e;
  }
}
