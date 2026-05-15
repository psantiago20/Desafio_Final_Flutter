import { get, post, put, del } from './client';
import { MENTORSHIP } from '../constants/api';

export function getMentorshipsApi(params) {
  return get(MENTORSHIP.LIST, { params });
}

export function getMentorshipByIdApi(id) {
  return get(MENTORSHIP.BY_ID(id));
}

export function createMentorshipApi(body) {
  return post(MENTORSHIP.CREATE, { body });
}

export function updateMentorshipApi(id, body) {
  return put(MENTORSHIP.UPDATE(id), { body });
}

export function deleteMentorshipApi(id) {
  return del(MENTORSHIP.DELETE(id));
}

export function getMentorshipSessionsApi(id, params) {
  return get(MENTORSHIP.SESSIONS(id), { params });
}

export function createSessionApi(id, body) {
  return post(MENTORSHIP.SESSIONS(id), { body });
}

export function getSessionByIdApi(mid, sid) {
  return get(MENTORSHIP.SESSION_BY_ID(mid, sid));
}

export function submitSessionFeedbackApi(mid, sid, body) {
  return post(MENTORSHIP.SESSION_FEEDBACK(mid, sid), { body });
}

export function getAvailableMentorsApi() {
  return get(MENTORSHIP.AVAILABLE);
}

export function applyForMentorshipApi(id) {
  return post(MENTORSHIP.APPLY(id));
}
