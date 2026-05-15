import {
  getTimelineApi, getExploreApi, getTrendingApi,
  getPostByIdApi, createPostApi, deletePostApi,
  likePostApi, unlikePostApi, repostPostApi,
  getCommentsApi, createCommentApi,
  getPostsByHashtagApi, getUserPostsApi, getUserLikesApi,
  uploadPostImageApi,
} from '../api/post.api.js';
import {
  setPosts, appendPosts, prependPost, updatePost, removePost,
  setCurrentPost, setTrending, setExplore, appendExplore,
  setPostLoading, setPostError,
} from '../state/post.store.js';
import { addErrorToast, addSuccessToast } from '../state/ui.store.js';

export async function loadTimeline(page = 0, size = 20) {
  setPostLoading(true);
  try {
    const data = await getTimelineApi(page, size);
    if (page === 0) {
      setPosts(data.content || [], { page, hasMore: !data.last, totalPages: data.totalPages, totalElements: data.totalElements });
    } else {
      appendPosts(data.content || [], { page, hasMore: !data.last, totalPages: data.totalPages, totalElements: data.totalElements });
    }
    return data;
  } catch (e) {
    setPostError(e.message);
    throw e;
  }
}

export async function loadExplore(page = 0, size = 20) {
  setPostLoading(true);
  try {
    const data = await getExploreApi(page, size);
    if (page === 0) {
      setExplore(data.content || [], { page, hasMore: !data.last });
    } else {
      appendExplore(data.content || [], { page, hasMore: !data.last });
    }
    return data;
  } catch (e) {
    setPostError(e.message);
    throw e;
  }
}

export async function loadTrending() {
  try {
    const data = await getTrendingApi();
    setTrending(data);
    return data;
  } catch (e) {
    console.error('Failed to load trending:', e);
  }
}

export async function loadPostDetail(postId) {
  setPostLoading(true);
  try {
    const data = await getPostByIdApi(postId);
    setCurrentPost(data);
    return data;
  } catch (e) {
    setPostError(e.message);
    throw e;
  }
}

export async function createPost(data) {
  try {
    const result = await createPostApi(data);
    prependPost(result);
    addSuccessToast('Post publicado!');
    return result;
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function deletePost(postId) {
  try {
    await deletePostApi(postId);
    removePost(postId);
    addSuccessToast('Post excluído');
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function likePost(postId) {
  updatePost(postId, { liked: true, likeCount: (post => {
    const p = findPostInStore(postId);
    return p ? p.likeCount + 1 : 1;
  })(null) });
  try {
    await likePostApi(postId);
  } catch (e) {
    updatePost(postId, { liked: false, likeCount: Math.max(0, (findPostInStore(postId)?.likeCount || 1) - 1) });
    addErrorToast('Erro ao curtir');
  }
}

export async function unlikePost(postId) {
  updatePost(postId, { liked: false, likeCount: Math.max(0, (findPostInStore(postId)?.likeCount || 1) - 1) });
  try {
    await unlikePostApi(postId);
  } catch (e) {
    updatePost(postId, { liked: true, likeCount: (findPostInStore(postId)?.likeCount || 0) + 1 });
    addErrorToast('Erro ao descurtir');
  }
}

export async function repostPost(postId) {
  try {
    await repostPostApi(postId);
    addSuccessToast('Repostado!');
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function loadComments(postId, page = 0, size = 20) {
  try {
    return await getCommentsApi(postId, page, size);
  } catch (e) {
    addErrorToast('Erro ao carregar comentários');
    throw e;
  }
}

export async function createComment(postId, content) {
  try {
    const result = await createCommentApi(postId, { content });
    return result;
  } catch (e) {
    addErrorToast(e.message);
    throw e;
  }
}

export async function loadHashtagPosts(tag, page = 0, size = 20) {
  setPostLoading(true);
  try {
    const data = await getPostsByHashtagApi(tag, page, size);
    if (page === 0) {
      setPosts(data.content || [], { page, hasMore: !data.last });
    } else {
      appendPosts(data.content || [], { page, hasMore: !data.last });
    }
    return data;
  } catch (e) {
    setPostError(e.message);
    throw e;
  }
}

export async function loadUserPosts(userId, page = 0, size = 20) {
  setPostLoading(true);
  try {
    const data = await getUserPostsApi(userId, page, size);
    if (page === 0) {
      setPosts(data.content || [], { page, hasMore: !data.last });
    } else {
      appendPosts(data.content || [], { page, hasMore: !data.last });
    }
    return data;
  } catch (e) {
    setPostError(e.message);
    throw e;
  }
}

export async function loadUserLikes(userId, page = 0, size = 20) {
  setPostLoading(true);
  try {
    const data = await getUserLikesApi(userId, page, size);
    if (page === 0) {
      setPosts(data.content || [], { page, hasMore: !data.last });
    } else {
      appendPosts(data.content || [], { page, hasMore: !data.last });
    }
    return data;
  } catch (e) {
    setPostError(e.message);
    throw e;
  }
}

export async function uploadPostImage(file) {
  const formData = new FormData();
  formData.append('file', file);
  try {
    return await uploadPostImageApi(formData);
  } catch (e) {
    addErrorToast('Erro ao enviar imagem');
    throw e;
  }
}

function findPostInStore(postId) {
  const { posts, currentPost } = postStore.state;
  return posts.find(p => p.id === postId) || (currentPost?.id === postId ? currentPost : null);
}
