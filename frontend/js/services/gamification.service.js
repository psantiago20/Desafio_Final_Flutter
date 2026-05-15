import {
  getUserStatsApi, getLeaderboardApi, getUserBadgesApi, getGamificationHistoryApi,
} from '../api/gamification.api.js';

export async function loadUserStats() {
  try {
    return await getUserStatsApi();
  } catch {
    return null;
  }
}

export async function loadLeaderboard(page = 0) {
  try {
    return await getLeaderboardApi(page);
  } catch {
    return { content: [] };
  }
}

export async function loadBadges() {
  try {
    return await getUserBadgesApi();
  } catch {
    return [];
  }
}

export async function loadGamificationHistory(page = 0) {
  try {
    return await getGamificationHistoryApi(page);
  } catch {
    return { content: [] };
  }
}
