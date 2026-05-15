import {
  getMentorshipsApi, getMentorshipByIdApi, createMentorshipApi,
  updateMentorshipApi, deleteMentorshipApi,
  getMentorshipSessionsApi, createMentorshipSessionApi,
  getMentorshipSessionByIdApi, updateMentorshipSessionApi,
  submitSessionFeedbackApi, getAvailableMentorsApi, applyForMentorshipApi,
} from '../api/mentorship.api.js';
import { addErrorToast, addSuccessToast } from '../state/ui.store.js';

export async function loadMentorships(page = 0, size = 20) {
  try {
    return await getMentorshipsApi(page, size);
  } catch (e) {
    addErrorToast('Erro ao carregar mentorias');
    throw e;
  }
}

export async function loadMentorshipDetail(id) {
  try {
    return await getMentorshipByIdApi(id);
  } catch (e) {
    addErrorToast('Erro ao carregar mentoria');
    throw e;
  }
}

export async function createMentorship(data) {
  try {
    const result = await createMentorshipApi(data);
    addSuccessToast('Mentoria criada!');
    return result;
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function updateMentorship(id, data) {
  try {
    const result = await updateMentorshipApi(id, data);
    addSuccessToast('Mentoria atualizada!');
    return result;
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function deleteMentorship(id) {
  try {
    await deleteMentorshipApi(id);
    addSuccessToast('Mentoria excluída');
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function loadSessions(mentorshipId, page = 0) {
  try {
    return await getMentorshipSessionsApi(mentorshipId, page);
  } catch (e) {
    addErrorToast('Erro ao carregar sessões');
    throw e;
  }
}

export async function createSession(mentorshipId, data) {
  try {
    const result = await createMentorshipSessionApi(mentorshipId, data);
    addSuccessToast('Sessão criada!');
    return result;
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function loadSessionDetail(mentorshipId, sessionId) {
  try {
    return await getMentorshipSessionByIdApi(mentorshipId, sessionId);
  } catch (e) {
    addErrorToast('Erro ao carregar sessão');
    throw e;
  }
}

export async function updateSession(mentorshipId, sessionId, data) {
  try {
    const result = await updateMentorshipSessionApi(mentorshipId, sessionId, data);
    addSuccessToast('Sessão atualizada!');
    return result;
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function submitFeedback(mentorshipId, sessionId, data) {
  try {
    const result = await submitSessionFeedbackApi(mentorshipId, sessionId, data);
    addSuccessToast('Feedback enviado!');
    return result;
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function loadAvailableMentors(page = 0) {
  try {
    return await getAvailableMentorsApi(page);
  } catch (e) {
    addErrorToast('Erro ao carregar mentores');
    throw e;
  }
}

export async function applyForMentorship(id) {
  try {
    await applyForMentorshipApi(id);
    addSuccessToast('Candidatura enviada!');
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}
