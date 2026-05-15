import { get } from './client';
import { GAMIFICATION } from '../constants/api';

export function getStatsApi() {
  return get(GAMIFICATION.STATS);
}

export function getLeaderboardApi(params) {
  return get(GAMIFICATION.LEADERBOARD, { params });
}

export function getBadgesApi() {
  return get(GAMIFICATION.BADGES);
}

export function getHistoryApi(params) {
  return get(GAMIFICATION.HISTORY, { params });
}
