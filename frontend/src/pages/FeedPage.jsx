import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useUI } from '../contexts/UIContext';
import PostComposer from '../components/PostComposer';
import PostCard from '../components/PostCard';
import LoadingSpinner from '../components/LoadingSpinner';
import useInfiniteScroll from '../hooks/useInfiniteScroll';
import { getTimelineApi, createPostApi, likePostApi, unlikePostApi, repostApi, uploadPostImageApi } from '../api/post.api';
import { copyToClipboard } from '../utils/helpers';

export default function FeedPage() {
  const navigate = useNavigate();
  const { addSuccessToast, addErrorToast } = useUI();
  const [posts, setPosts] = useState([]);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  const loadPosts = useCallback(async (p) => {
    try {
      const data = await getTimelineApi({ page: p, size: 20 });
      if (p === 0) {
        setPosts(data.content || []);
      } else {
        setPosts(prev => [...prev, ...(data.content || [])]);
      }
      setHasMore(!data.last);
      setPage(p);
      return data;
    } catch (e) {
      setError(e.message);
      throw e;
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => { loadPosts(0); }, [loadPosts]);

  const loadMore = useCallback(async () => {
    if (!hasMore) return;
    return loadPosts(page + 1);
  }, [hasMore, page, loadPosts]);

  const { sentinelRef } = useInfiniteScroll(loadMore, { enabled: hasMore && !isLoading });

  const handleCreatePost = async (data) => {
    const payload = { content: data.content, visibility: data.visibility };
    if (data.imageFile) {
      const formData = new FormData();
      formData.append('file', data.imageFile);
      const uploadResult = await uploadPostImageApi(formData);
      payload.imageUrl = uploadResult.url || uploadResult.imageUrl;
    }
    const result = await createPostApi(payload);
    setPosts(prev => [result, ...prev]);
    addSuccessToast('Post publicado!');
  };

  const handleLike = async (postId) => {
    setPosts(prev => prev.map(p =>
      p.id === postId
        ? { ...p, liked: !p.liked, likeCount: p.liked ? p.likeCount - 1 : p.likeCount + 1 }
        : p
    ));
    try {
      const post = posts.find(p => p.id === postId);
      if (post?.liked) {
        await unlikePostApi(postId);
      } else {
        await likePostApi(postId);
      }
    } catch {
      setPosts(prev => prev.map(p =>
        p.id === postId
          ? { ...p, liked: !p.liked, likeCount: p.liked ? p.likeCount - 1 : p.likeCount + 1 }
          : p
      ));
      addErrorToast('Erro ao curtir');
    }
  };

  const handleRepost = async (postId) => {
    try {
      await repostApi(postId);
      addSuccessToast('Repostado!');
    } catch (e) {
      addErrorToast(e.message);
    }
  };

  const handleShare = (postId) => {
    const url = `${window.location.origin}/post/${postId}`;
    if (navigator.share) {
      navigator.share({ url }).catch(() => {});
    } else {
      copyToClipboard(url);
      addSuccessToast('Link copiado!');
    }
  };

  if (isLoading && posts.length === 0) {
    return <LoadingSpinner size="lg" text="Carregando feed..." />;
  }

  if (error && posts.length === 0) {
    return (
      <div className="feed-error">
        <p>{error}</p>
        <button className="btn btn-secondary btn-sm mt-md" onClick={() => { setIsLoading(true); setError(null); loadPosts(0); }}>
          Tentar novamente
        </button>
      </div>
    );
  }

  return (
    <div className="feed-page">
      <div className="page-header">
        <div className="timeline-header">
          <h2 className="page-title">Feed</h2>
        </div>
      </div>
      <PostComposer onSubmit={handleCreatePost} />
      {posts.length === 0 ? (
        <div className="empty-state">
          <div className="empty-state-icon">📭</div>
          <div className="empty-state-text">Nenhum post encontrado</div>
          <p className="text-muted mt-sm">Siga outros usuários para ver posts aqui</p>
        </div>
      ) : (
        <div className="feed-posts">
          {posts.map(post => (
            <div key={post.id} onClick={() => navigate(`/post/${post.id}`)} style={{ cursor: 'pointer' }}>
              <PostCard
                post={post}
                onLike={handleLike}
                onComment={(id) => navigate(`/post/${id}`)}
                onRepost={handleRepost}
                onShare={handleShare}
              />
            </div>
          ))}
        </div>
      )}
      {isLoading && posts.length > 0 && (
        <div className="loading-inline"><div className="spinner"></div></div>
      )}
      {!hasMore && posts.length > 0 && (
        <div className="text-center text-muted py-md" style={{ padding: 16 }}>Você viu tudo!</div>
      )}
      <div ref={sentinelRef} className="infinite-scroll-trigger" />
    </div>
  );
}
