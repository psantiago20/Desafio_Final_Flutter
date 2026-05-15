import { get, post, put, del, upload } from './client';
import { USER } from '../constants/api';

export function getProfileApi() {
  return get(USER.PROFILE);
}

export function getUserByIdApi(id) {
  return get(USER.USER_BY_ID(id));
}

export function getFollowersApi(id, params) {
  return get(USER.FOLLOWERS(id), { params });
}

export function getFollowingApi(id, params) {
  return get(USER.FOLLOWING(id), { params });
}

export function followUserApi(id) {
  return post(USER.FOLLOW(id));
}

export function unfollowUserApi(id) {
  return del(USER.UNFOLLOW(id));
}

export function getInterestsApi() {
  return get(USER.INTERESTS);
}

export function updateInterestsApi(interests) {
  return put(USER.INTERESTS, { body: { interests } });
}

export function uploadAvatarApi(formData) {
  return upload(USER.AVATAR, formData);
}

export function uploadBannerApi(formData) {
  return upload(USER.BANNER, formData);
}

export function searchUsersApi(params) {
  return get(USER.SEARCH, { params });
}
