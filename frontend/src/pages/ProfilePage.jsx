import { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useUI } from '../contexts/UIContext';
import PostCard from '../components/PostCard';
import LoadingSpinner from '../components/LoadingSpinner';
import useInfiniteScroll from '../hooks/useInfiniteScroll';
import { getProfileApi, getUserByIdApi, followUserApi, unfollowUserApi } from '../api/user.api';
import { getUserPostsApi, getUserLikesApi, likePostApi, unlikePostApi } from '../api/post.api';
import { formatNumber } from '../utils/format';
import { escapeHtml, getInitials } from '../utils/helpers';

export default function ProfilePage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { user: currentUser } = useAuth();
  const { addErrorToast } = useUI();

  const [profile, setProfile] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isOwnProfile, setIsOwnProfile] = useState(false);
  const [isFollowing, setIsFollowing] = useState(false);
  const [followersCount, setFollowersCount] = useState(0);
  const [followingCount, setFollowingCount] = useState(0);
  const [postsCount, setPostsCount] = useState(0);
  const [tab, setTab] = useState('posts');
  const [posts, setPosts] = useState([]);
  const [postPage, setPostPage] = useState(0);
  const [hasMorePosts, setHasMorePosts] = useState(true);
  const [isLoadingPosts, setIsLoadingPosts] = useState(false);

  const userId = id || currentUser?.id;

  const loadProfile = useCallback(async () => {
    setIsLoading(true);
    try {
      const isOwn = !id || id === String(currentUser?.id);
      setIsOwnProfile(isOwn);
      if (isOwn) {
        setProfile(currentUser);
        setFollowersCount(currentUser?.followersCount || 0);
        setFollowingCount(currentUser?.followingCount || 0);
        setPostsCount(currentUser?.postsCount || 0);
      } else {
        const p = await getUserByIdApi(id);
        setProfile(p);
        setIsFollowing(p.isFollowing || false);
        setFollowersCount(p.followersCount || 0);
        setFollowingCount(p.followingCount || 0);
        setPostsCount(p.postsCount || 0);
      }
    } catch {
      setProfile(null);
    } finally {
      setIsLoading(false);
    }
  }, [id, currentUser]);

  const loadPosts = useCallback(async (p) => {
    if (!userId) return;
    setIsLoadingPosts(true);
    try {
      let data;
      if (tab === 'posts') {
        data = await getUserPostsApi(userId, { page: p, size: 20 });
      } else {
        data = await getUserLikesApi(userId, { page: p, size: 20 });
      }
      if (p === 0) {
        setPosts(data.content || []);
      } else {
        setPosts(prev => [...prev, ...(data.content || [])]);
      }
      setHasMorePosts(!data.last);
      setPostPage(p);
    } catch {
      addErrorToast('Erro ao carregar posts');
    } finally {
      setIsLoadingPosts(false);
    }
  }, [userId, tab, addErrorToast]);

  useEffect(() => { loadProfile(); }, [loadProfile]);
  useEffect(() => { setPosts([]); setPostPage(0); setHasMorePosts(true); loadPosts(0); }, [tab, loadPosts]);

  const loadMorePosts = useCallback(async () => {
    if (!hasMorePosts || isLoadingPosts) return;
    return loadPosts(postPage + 1);
  }, [hasMorePosts, isLoadingPosts, postPage, loadPosts]);

  const { sentinelRef } = useInfiniteScroll(loadMorePosts, { enabled: hasMorePosts && !isLoadingPosts });

  const handleFollowToggle = async () => {
    if (!profile?.id) return;
    try {
      if (isFollowing) {
        await unfollowUserApi(profile.id);
        setIsFollowing(false);
        setFollowersCount(prev => prev - 1);
      } else {
        await followUserApi(profile.id);
        setIsFollowing(true);
        setFollowersCount(prev => prev + 1);
      }
    } catch {
      addErrorToast('Erro ao seguir/deixar de seguir');
    }
  };

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
    }
  };

  if (isLoading) return <LoadingSpinner size="lg" />;

  if (!profile) {
    return (
      <div className="empty-state">
        <div className="empty-state-text">Usuário não encontrado</div>
      </div>
    );
  }

  const avatar = profile.avatarUrl || '';
  const banner = profile.bannerUrl || '';
  const initials = getInitials(profile.name);

  return (
    <div className="profile-page">
      <div className="profile-header-section">
        <div className="profile-banner-img" style={{
          backgroundImage: banner ? `url(${banner})` : undefined,
          backgroundSize: 'cover', backgroundPosition: 'center',
          height: 160, backgroundColor: 'var(--bg-tertiary)',
        }} />
      </div>

      <div className="profile-info-section">
        <div className="profile-avatar-section">
          {avatar
            ? <img src={avatar} alt="" className="avatar avatar-xl" />
            : <div className="avatar avatar-xl avatar-placeholder" style={{ fontSize: 36 }}>{initials}</div>
          }
        </div>

        <div className="profile-action-row">
          {isOwnProfile
            ? <button className="btn btn-outline btn-sm" onClick={() => navigate('/profile/edit')}>Editar perfil</button>
            : <button className={`btn ${isFollowing ? 'btn-outline' : 'btn-primary'} btn-sm`} onClick={handleFollowToggle}>
                {isFollowing ? 'Seguindo' : 'Seguir'}
              </button>
          }
        </div>

        <div className="profile-display-name">{escapeHtml(profile.name || '')}</div>
        <div className="profile-handle">@{escapeHtml(profile.username || '')}</div>

        {profile.bio && <div className="profile-bio-text">{escapeHtml(profile.bio)}</div>}

        <div className="profile-details">
          {profile.location && <span className="profile-detail-item">📍 {escapeHtml(profile.location)}</span>}
          {profile.institution && <span className="profile-detail-item">🏛️ {escapeHtml(profile.institution)}</span>}
        </div>

        <div className="profile-numbers">
          <span className="profile-number">
            <span className="profile-number-value">{formatNumber(postsCount)}</span>
            <span className="profile-number-label">Posts</span>
          </span>
          <span className="profile-number">
            <span className="profile-number-value">{formatNumber(followersCount)}</span>
            <span className="profile-number-label">Seguidores</span>
          </span>
          <span className="profile-number">
            <span className="profile-number-value">{formatNumber(followingCount)}</span>
            <span className="profile-number-label">Seguindo</span>
          </span>
        </div>
      </div>

      <div className="profile-content-tabs">
        {['posts', 'likes', 'media'].map(t => (
          <div key={t}
            className={`profile-content-tab ${tab === t ? 'active' : ''}`}
            onClick={() => setTab(t)}
          >
            {t === 'posts' ? 'Posts' : t === 'likes' ? 'Curtidas' : 'Mídia'}
          </div>
        ))}
      </div>

      {posts.length === 0 && !isLoadingPosts ? (
        <div className="empty-state">
          <div className="empty-state-text">Nenhum post encontrado</div>
        </div>
      ) : (
        <div className="feed-posts">
          {posts.map(post => (
            <div key={post.id} onClick={() => navigate(`/post/${post.id}`)} style={{ cursor: 'pointer' }}>
              <PostCard post={post} onLike={handleLike} onComment={(pid) => navigate(`/post/${pid}`)} />
            </div>
          ))}
        </div>
      )}

      {isLoadingPosts && <div className="loading-inline"><div className="spinner"></div></div>}
      {!hasMorePosts && posts.length > 0 && (
        <div className="text-center text-muted py-md" style={{ padding: 16 }}>Você viu tudo!</div>
      )}
      <div ref={sentinelRef} className="infinite-scroll-trigger" />
    </div>
  );
}
