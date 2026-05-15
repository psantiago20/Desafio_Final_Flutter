import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useUI } from '../contexts/UIContext';
import PostComposer from '../components/PostComposer';
import PostCard from '../components/PostCard';
import LoadingSpinner from '../components/LoadingSpinner';
import { getGroupByIdApi, joinGroupApi, leaveGroupApi, getGroupMembersApi } from '../api/group.api';
import { createPostApi, likePostApi, unlikePostApi, uploadPostImageApi } from '../api/post.api';
import { escapeHtml, getInitials } from '../utils/helpers';
import { formatNumber } from '../utils/format';

export default function GroupDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { addSuccessToast, addErrorToast } = useUI();
  const [group, setGroup] = useState(null);
  const [posts, setPosts] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isMember, setIsMember] = useState(false);
  const [memberCount, setMemberCount] = useState(0);

  useEffect(() => {
    async function load() {
      setIsLoading(true);
      try {
        const g = await getGroupByIdApi(id);
        setGroup(g);
        setIsMember(g.isMember || false);
        setMemberCount(g.memberCount || 0);
      } catch { setGroup(null); }
      setIsLoading(false);
    }
    load();
  }, [id]);

  const handleJoinToggle = async () => {
    try {
      if (isMember) {
        await leaveGroupApi(id);
        setIsMember(false);
        setMemberCount(prev => prev - 1);
      } else {
        await joinGroupApi(id);
        setIsMember(true);
        setMemberCount(prev => prev + 1);
      }
    } catch { addErrorToast('Erro ao entrar/sair'); }
  };

  const handleCreatePost = async (data) => {
    const payload = { content: data.content, visibility: data.visibility, groupId: id };
    if (data.imageFile) {
      const formData = new FormData();
      formData.append('file', data.imageFile);
      const uploadResult = await uploadPostImageApi(formData);
      payload.imageUrl = uploadResult.url || uploadResult.imageUrl;
    }
    const post = await createPostApi(payload);
    setPosts(prev => [post, ...prev]);
    addSuccessToast('Post publicado!');
  };

  const handleLike = async (postId) => {
    setPosts(prev => prev.map(p =>
      p.id === postId ? { ...p, liked: !p.liked, likeCount: p.liked ? p.likeCount - 1 : p.likeCount + 1 } : p
    ));
    try {
      const post = posts.find(p => p.id === postId);
      if (post?.liked) await unlikePostApi(postId);
      else await likePostApi(postId);
    } catch { addErrorToast('Erro ao curtir'); }
  };

  if (isLoading) return <LoadingSpinner size="lg" />;
  if (!group) return <div className="empty-state"><div className="empty-state-text">Grupo não encontrado</div></div>;

  const banner = group.bannerUrl || '';
  const avatar = group.avatarUrl || '';
  const initials = getInitials(group.name);

  return (
    <div className="group-detail-page">
      <div className="profile-header-section">
        <div className="profile-banner-img" style={{
          backgroundImage: banner ? `url(${banner})` : undefined,
          backgroundSize: 'cover', backgroundPosition: 'center',
          height: 160, backgroundColor: 'var(--bg-tertiary)',
        }} />
      </div>

      <div className="profile-info-section">
        <div className="profile-avatar-section" style={{ top: -48 }}>
          {avatar
            ? <img src={avatar} alt="" className="avatar avatar-lg" />
            : <div className="avatar avatar-lg avatar-placeholder" style={{ fontSize: 20 }}>{initials}</div>
          }
        </div>

        <div className="profile-action-row">
          <button className={`btn ${isMember ? 'btn-outline' : 'btn-primary'} btn-sm`} onClick={handleJoinToggle}>
            {isMember ? 'Sair do grupo' : 'Entrar no grupo'}
          </button>
        </div>

        <div className="profile-display-name">{escapeHtml(group.name || '')}</div>
        {group.category && <div className="profile-handle">{escapeHtml(group.category)}</div>}
        {group.description && <div className="profile-bio-text">{escapeHtml(group.description)}</div>}

        <div className="profile-numbers">
          <span className="profile-number">
            <span className="profile-number-value">{formatNumber(memberCount)}</span>
            <span className="profile-number-label">Membros</span>
          </span>
        </div>
      </div>

      {isMember && <PostComposer onSubmit={handleCreatePost} />}

      <div className="profile-content-tabs">
        <div className="profile-content-tab active">Posts</div>
        <div className="profile-content-tab">Membros ({memberCount})</div>
      </div>

      {posts.length === 0
        ? <div className="empty-state"><div className="empty-state-text">Nenhum post no grupo</div></div>
        : posts.map(post => (
            <div key={post.id} onClick={() => navigate(`/post/${post.id}`)} style={{ cursor: 'pointer' }}>
              <PostCard post={post} onLike={handleLike} onComment={(pid) => navigate(`/post/${pid}`)} />
            </div>
          ))
      }
    </div>
  );
}
