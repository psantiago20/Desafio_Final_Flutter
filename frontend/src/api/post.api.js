import { get, post, put, del, upload } from './client';
import { POST } from '../constants/api';

export function getTimelineApi(params) {
  return get(POST.TIMELINE, { params });
}

export function getExploreApi(params) {
  return get(POST.EXPLORE, { params });
}

export function getTrendingApi() {
  return get(POST.TRENDING);
}

export function getPostByIdApi(id) {
  return get(POST.BY_ID(id));
}

export function createPostApi(body) {
  return post(POST.CREATE, { body });
}

export function deletePostApi(id) {
  return del(POST.DELETE(id));
}

export function likePostApi(id) {
  return post(POST.LIKE(id));
}

export function unlikePostApi(id) {
  return del(POST.UNLIKE(id));
}

export function repostApi(id) {
  return post(POST.REPOST(id));
}

export function getCommentsApi(id, params) {
  return get(POST.COMMENTS(id), { params });
}

export function createCommentApi(id, body) {
  return post(POST.COMMENT_CREATE(id), { body });
}

export function getPostsByUserApi(userId, params) {
  return get(POST.USER_POSTS(userId), { params });
}

export function getUserPostsApi(userId, params) {
  return get(POST.USER_POSTS(userId), { params });
}

export function getUserLikesApi(userId, params) {
  return get(POST.USER_LIKES(userId), { params });
}

export function getPostsByHashtagApi(tag, params) {
  return get(POST.HASHTAG(tag), { params });
}

export function uploadPostImageApi(formData) {
  return upload(POST.UPLOAD_IMAGE, formData);
}
