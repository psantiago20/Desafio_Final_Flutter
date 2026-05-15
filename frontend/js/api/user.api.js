import { get, put, post, del } from './client.js';
import { USER } from '../constants/api.js';

export function getProfileApi() {
  return get(USER.PROFILE);
}

export function getUserByIdApi(id) {
  return get(USER.USER_BY_ID(id));
}

export function updateProfileApi(data) {
  return put(USER.PROFILE, { body: data });
}

export function getFollowersApi(id, page = 0, size = 20) {
  return get(USER.FOLLOWERS(id), { params: { page, size } });
}

export function getFollowingApi(id, page = 0, size = 20) {
  return get(USER.FOLLOWING(id), { params: { page, size } });
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
  return post(USER.AVATAR, { formData });
}

export function uploadBannerApi(formData) {
  return post(USER.BANNER, { formData });
}

export function searchUsersApi(query, page = 0, size = 20) {
  return get(USER.SEARCH, { params: { query, page, size } });
}
