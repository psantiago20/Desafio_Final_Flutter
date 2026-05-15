import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useUI } from '../contexts/UIContext';
import PostCard from '../components/PostCard';
import LoadingSpinner from '../components/LoadingSpinner';
import useInfiniteScroll from '../hooks/useInfiniteScroll';
import { getExploreApi, getTrendingApi, likePostApi, unlikePostApi } from '../api/post.api';

export default function ExplorePage() {
  const navigate = useNavigate();
  const { addErrorToast } = useUI();
  const [posts, setPosts] = useState([]);
  const [trending, setTrending] = useState([]);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');

  const loadPosts = useCallback(async (p) => {
    try {
      const data = await getExploreApi({ page: p, size: 20 });
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

  useEffect(() => {
    loadPosts(0);
    getTrendingApi().then(setTrending).catch(() => {});
  }, [loadPosts]);

  const loadMore = useCallback(async () => {
    if (!hasMore) return;
    return loadPosts(page + 1);
  }, [hasMore, page, loadPosts]);

  const { sentinelRef } = useInfiniteScroll(loadMore, { enabled: hasMore && !isLoading });

  const handleLike = async (postId) => {
    setPosts(prev => prev.map(p =>
      p.id === postId ? { ...p, liked: !p.liked, likeCount: p.liked ? p.likeCount - 1 : p.likeCount + 1 } : p
    ));
    try {
      const post = posts.find(p => p.id === postId);
      if (post?.liked) await unlikePostApi(postId);
      else await likePostApi(postId);
    } catch {
      setPosts(prev => prev.map(p =>
        p.id === postId ? { ...p, liked: !p.liked, likeCount: p.liked ? p.likeCount - 1 : p.likeCount + 1 } : p
      ));
      addErrorToast('Erro ao curtir');
    }
  };

  if (isLoading && posts.length === 0) return <LoadingSpinner size="lg" text="Carregando..." />;

  return (
    <div className="explore-page">
      <div className="page-header">
        <h2 className="page-title">Explorar</h2>
        <div className="search-bar mt-sm">
          <span className="search-icon">🔍</span>
          <input type="search" placeholder="Buscar posts..." value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)} />
        </div>
      </div>

      {trending.length > 0 && (
        <div style={{ padding: 'var(--spacing-sm) var(--spacing-lg)', display: 'flex', gap: 8, flexWrap: 'wrap', borderBottom: '1px solid var(--border-primary)' }}>
          {trending.slice(0, 8).map(t => (
            <span key={t.hashtag || t.tag} className="chip"
              onClick={() => navigate(`/explore?tag=${encodeURIComponent(t.hashtag || t.tag)}`)}>
              #{t.hashtag || t.tag}
            </span>
          ))}
        </div>
      )}

      {posts.length === 0 && !isLoading ? (
        <div className="empty-state">
          <div className="empty-state-icon">🔍</div>
          <div className="empty-state-text">Nenhum post encontrado</div>
        </div>
      ) : (
        <div className="feed-posts">
          {posts.map(post => (
            <div key={post.id} onClick={() => navigate(`/post/${post.id}`)} style={{ cursor: 'pointer' }}>
              <PostCard post={post} onLike={handleLike} onComment={(id) => navigate(`/post/${id}`)} />
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
