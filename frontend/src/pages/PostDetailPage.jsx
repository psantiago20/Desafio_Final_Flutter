import { useState, useEffect, useRef, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useUI } from '../contexts/UIContext';
import PostCard from '../components/PostCard';
import CommentItem from '../components/CommentItem';
import LoadingSpinner from '../components/LoadingSpinner';
import { getPostByIdApi, getCommentsApi, createCommentApi, likePostApi, unlikePostApi, repostApi } from '../api/post.api';
import { getInitials } from '../utils/helpers';
import { copyToClipboard } from '../utils/helpers';

export default function PostDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { addSuccessToast, addErrorToast } = useUI();
  const [post, setPost] = useState(null);
  const [comments, setComments] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [commentText, setCommentText] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const inputRef = useRef(null);

  useEffect(() => {
    async function load() {
      setIsLoading(true);
      try {
        const postData = await getPostByIdApi(id);
        setPost(postData);
      } catch {
        setPost(null);
      }
      try {
        const data = await getCommentsApi(id);
        setComments(data.content || data || []);
      } catch {}
      setIsLoading(false);
    }
    load();
  }, [id]);

  const handleSubmitComment = useCallback(async () => {
    const content = commentText.trim();
    if (!content || isSubmitting) return;
    setIsSubmitting(true);
    try {
      const result = await createCommentApi(id, { content });
      setComments(prev => [...prev, result]);
      setCommentText('');
    } catch {
      addErrorToast('Erro ao comentar');
    } finally {
      setIsSubmitting(false);
    }
  }, [commentText, isSubmitting, id, addErrorToast]);

  const handleLike = async () => {
    if (!post) return;
    const wasLiked = post.liked;
    setPost(prev => ({ ...prev, liked: !prev.liked, likeCount: prev.liked ? prev.likeCount - 1 : prev.likeCount + 1 }));
    try {
      if (wasLiked) await unlikePostApi(post.id);
      else await likePostApi(post.id);
    } catch {
      setPost(prev => ({ ...prev, liked: wasLiked, likeCount: wasLiked ? prev.likeCount + 1 : prev.likeCount - 1 }));
    }
  };

  const handleRepost = async () => {
    try {
      await repostApi(post.id);
      addSuccessToast('Repostado!');
    } catch (e) {
      addErrorToast(e.message);
    }
  };

  const handleShare = () => {
    const url = `${window.location.origin}/post/${post.id}`;
    if (navigator.share) navigator.share({ url }).catch(() => {});
    else { copyToClipboard(url); addSuccessToast('Link copiado!'); }
  };

  if (isLoading) return <LoadingSpinner size="lg" />;

  if (!post) {
    return (
      <div className="empty-state">
        <div className="empty-state-text">Post não encontrado</div>
      </div>
    );
  }

  const avatar = user?.avatarUrl || '';
  const initials = getInitials(user?.name);

  return (
    <div className="post-detail-page">
      <div className="page-header">
        <div className="flex items-center gap-md">
          <button className="nav-icon-btn" onClick={() => navigate(-1)}>←</button>
          <h2 className="page-title">Post</h2>
        </div>
      </div>

      <PostCard
        post={post}
        onLike={handleLike}
        onComment={() => {}}
        onRepost={handleRepost}
        onShare={handleShare}
      />

      <div style={{ padding: 'var(--spacing-md) var(--spacing-lg)', borderBottom: '1px solid var(--border-primary)' }}>
        <div className="flex gap-sm">
          {avatar
            ? <img src={avatar} alt="" className="avatar avatar-sm" />
            : <div className="avatar avatar-sm avatar-placeholder" style={{ fontSize: 12 }}>{initials}</div>
          }
          <div style={{ flex: 1, display: 'flex', gap: 8 }}>
            <input
              ref={inputRef}
              type="text"
              placeholder="Escreva um comentário..."
              value={commentText}
              onChange={(e) => setCommentText(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); handleSubmitComment(); } }}
              style={{ border: 'none', background: 'var(--bg-input)', flex: 1, borderRadius: 'var(--radius-md)', padding: '10px 14px', color: 'var(--text-primary)' }}
            />
            <button
              className="btn btn-primary btn-sm"
              disabled={!commentText.trim() || isSubmitting}
              onClick={handleSubmitComment}
            >
              {isSubmitting ? '...' : 'Enviar'}
            </button>
          </div>
        </div>
      </div>

      <div>
        {comments.length > 0
          ? comments.map(c => (
              <div key={c.id} style={{ padding: '12px var(--spacing-lg)', borderBottom: '1px solid var(--border-secondary)' }}>
                <CommentItem comment={c} />
              </div>
            ))
          : <div className="text-center text-muted" style={{ padding: 24 }}>Nenhum comentário ainda</div>
        }
      </div>
    </div>
  );
}
