import Store from './Store.js';

const initialState = {
  posts: [],
  currentPost: null,
  trending: [],
  explore: [],
  pagination: {
    page: 0,
    totalPages: 0,
    totalElements: 0,
    hasMore: true,
  },
  isLoading: false,
  error: null,
};

const postStore = new Store(initialState);

export function setPosts(posts, pagination) {
  postStore.set({ posts, pagination, isLoading: false, error: null });
}

export function appendPosts(newPosts, pagination) {
  const current = postStore.get('posts');
  postStore.set({ posts: [...current, ...newPosts], pagination, isLoading: false });
}

export function prependPost(post) {
  const current = postStore.get('posts');
  postStore.set({ posts: [post, ...current] });
}

export function updatePost(postId, updates) {
  const posts = postStore.get('posts').map(p => {
    if (p.id === postId) return { ...p, ...updates };
    if (p.repostOf && p.repostOf.id === postId) return { ...p, repostOf: { ...p.repostOf, ...updates } };
    return p;
  });
  postStore.set({ posts });

  const currentPost = postStore.get('currentPost');
  if (currentPost && currentPost.id === postId) {
    postStore.set({ currentPost: { ...currentPost, ...updates } });
  }
}

export function removePost(postId) {
  const posts = postStore.get('posts').filter(p => p.id !== postId);
  postStore.set({ posts });
}

export function setCurrentPost(post) {
  postStore.set({ currentPost: post });
}

export function setTrending(trending) {
  postStore.set({ trending });
}

export function setExplore(posts, pagination) {
  postStore.set({ explore: posts, pagination, isLoading: false });
}

export function appendExplore(newPosts, pagination) {
  const current = postStore.get('explore');
  postStore.set({ explore: [...current, ...newPosts], pagination, isLoading: false });
}

export function setPostLoading(loading) {
  postStore.set({ isLoading: loading });
}

export function setPostError(error) {
  postStore.set({ error, isLoading: false });
}

export function resetPosts() {
  postStore.set({
    posts: [],
    currentPost: null,
    pagination: { page: 0, totalPages: 0, totalElements: 0, hasMore: true },
    isLoading: false,
    error: null,
  });
}

export default postStore;
