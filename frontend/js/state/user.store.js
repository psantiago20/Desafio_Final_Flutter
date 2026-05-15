import Store from './Store.js';

const initialState = {
  profile: null,
  followers: [],
  following: [],
  interests: [],
  followersCount: 0,
  followingCount: 0,
  postsCount: 0,
  isLoading: false,
  error: null,
};

const userStore = new Store(initialState);

export function setProfile(profile) {
  userStore.set({
    profile,
    followersCount: profile.followersCount || 0,
    followingCount: profile.followingCount || 0,
    postsCount: profile.postsCount || 0,
  });
}

export function setFollowers(followers) {
  userStore.set({ followers });
}

export function setFollowing(following) {
  userStore.set({ following });
}

export function setInterests(interests) {
  userStore.set({ interests });
}

export function setUserLoading(loading) {
  userStore.set({ isLoading: loading });
}

export function setUserError(error) {
  userStore.set({ error, isLoading: false });
}

export default userStore;
