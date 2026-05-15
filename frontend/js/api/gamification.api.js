import { get, post } from './client.js';
import { GAMIFICATION } from '../constants/api.js';

export function getUserStatsApi() {
  return get(GAMIFICATION.STATS);
}

export function getLeaderboardApi(page = 0, size = 20) {
  return get(GAMIFICATION.LEADERBOARD, { params: { page, size } });
}

export function getUserBadgesApi() {
  return get(GAMIFICATION.BADGES);
}

export function getGamificationHistoryApi(page = 0, size = 20) {
  return get(GAMIFICATION.HISTORY, { params: { page, size } });
}
