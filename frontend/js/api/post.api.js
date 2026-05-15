import { get, post, put, del } from './client.js';
import { POST } from '../constants/api.js';

export function getTimelineApi(page = 0, size = 20) {
  return get(POST.TIMELINE, { params: { page, size } });
}

export function getExploreApi(page = 0, size = 20) {
  return get(POST.EXPLORE, { params: { page, size } });
}

export function getTrendingApi() {
  return get(POST.TRENDING);
}

export function getPostByIdApi(id) {
  return get(POST.BY_ID(id));
}

export function createPostApi(data) {
  return post(POST.CREATE, { body: data });
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

export function repostPostApi(id) {
  return post(POST.REPOST(id));
}

export function getCommentsApi(postId, page = 0, size = 20) {
  return get(POST.COMMENTS(postId), { params: { page, size } });
}

export function createCommentApi(postId, data) {
  return post(POST.COMMENT_CREATE(postId), { body: data });
}

export function getPostsByHashtagApi(tag, page = 0, size = 20) {
  return get(POST.HASHTAG(tag), { params: { page, size } });
}

export function getUserPostsApi(userId, page = 0, size = 20) {
  return get(POST.USER_POSTS(userId), { params: { page, size } });
}

export function getUserLikesApi(userId, page = 0, size = 20) {
  return get(POST.USER_LIKES(userId), { params: { page, size } });
}

export function uploadPostImageApi(formData) {
  return post(POST.UPLOAD_IMAGE, { formData });
}
