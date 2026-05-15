import { get, post, put, del } from './client.js';
import { MENTORSHIP } from '../constants/api.js';

export function getMentorshipsApi(page = 0, size = 20) {
  return get(MENTORSHIP.LIST, { params: { page, size } });
}

export function getMentorshipByIdApi(id) {
  return get(MENTORSHIP.BY_ID(id));
}

export function createMentorshipApi(data) {
  return post(MENTORSHIP.CREATE, { body: data });
}

export function updateMentorshipApi(id, data) {
  return put(MENTORSHIP.UPDATE(id), { body: data });
}

export function deleteMentorshipApi(id) {
  return del(MENTORSHIP.DELETE(id));
}

export function getMentorshipSessionsApi(mentorshipId, page = 0, size = 20) {
  return get(MENTORSHIP.SESSIONS(mentorshipId), { params: { page, size } });
}

export function createMentorshipSessionApi(mentorshipId, data) {
  return post(MENTORSHIP.SESSIONS(mentorshipId), { body: data });
}

export function getMentorshipSessionByIdApi(mentorshipId, sessionId) {
  return get(MENTORSHIP.SESSION_BY_ID(mentorshipId, sessionId));
}

export function updateMentorshipSessionApi(mentorshipId, sessionId, data) {
  return put(MENTORSHIP.SESSION_BY_ID(mentorshipId, sessionId), { body: data });
}

export function submitSessionFeedbackApi(mentorshipId, sessionId, data) {
  return post(MENTORSHIP.SESSION_FEEDBACK(mentorshipId, sessionId), { body: data });
}

export function getAvailableMentorsApi(page = 0, size = 20) {
  return get(MENTORSHIP.AVAILABLE, { params: { page, size } });
}

export function applyForMentorshipApi(id) {
  return post(MENTORSHIP.APPLY(id));
}
