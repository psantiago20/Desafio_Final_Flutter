import { useState, useRef, useEffect, useCallback } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { MAX_POST_LENGTH, VISIBILITY } from '../constants/config';
import { getInitials } from '../utils/helpers';

export default function PostComposer({ onSubmit }) {
  const { user } = useAuth();
  const [content, setContent] = useState('');
  const [visibility, setVisibility] = useState(VISIBILITY.PUBLIC);
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const textareaRef = useRef(null);

  const remaining = MAX_POST_LENGTH - content.length;
  const showWarning = content.length > MAX_POST_LENGTH * 0.9;
  const showDanger = content.length >= MAX_POST_LENGTH;
  const avatar = user?.avatarUrl || '';
  const initials = getInitials(user?.name);

  const autoResize = useCallback(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = textareaRef.current.scrollHeight + 'px';
    }
  }, []);

  useEffect(() => {
    autoResize();
  }, [content, autoResize]);

  const handleImageSelect = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 5 * 1024 * 1024) {
      alert('Imagem muito grande. Máximo 5MB.');
      return;
    }
    setImageFile(file);
    const reader = new FileReader();
    reader.onload = (ev) => setImagePreview(ev.target.result);
    reader.readAsDataURL(file);
  };

  const handleSubmit = async () => {
    if (isSubmitting || !content.trim() || showDanger) return;
    setIsSubmitting(true);
    try {
      await onSubmit({ content: content.trim(), visibility, imageFile });
      setContent('');
      setImageFile(null);
      setImagePreview(null);
    } catch {
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="post-composer">
      <div className="flex gap-sm">
        <div className="post-card-avatar">
          {avatar
            ? <img src={avatar} alt="" className="avatar" />
            : <div className="avatar avatar-placeholder">{initials}</div>
          }
        </div>
        <div className="flex-col" style={{ flex: 1 }}>
          <textarea
            ref={textareaRef}
            className="post-composer-textarea"
            placeholder="O que está acontecendo?"
            maxLength={MAX_POST_LENGTH}
            value={content}
            onChange={(e) => setContent(e.target.value)}
          />
          {imagePreview && (
            <div className="composer-image-preview" style={{ position: 'relative', display: 'inline-block', marginTop: 8 }}>
              <img src={imagePreview} alt="" style={{ maxHeight: 200, borderRadius: 8 }} />
              <button
                onClick={() => { setImageFile(null); setImagePreview(null); }}
                style={{ position: 'absolute', top: 4, right: 4, background: 'var(--bg-modal-overlay)', color: '#fff', borderRadius: '50%', width: 28, height: 28, border: 'none', cursor: 'pointer' }}
              >✕</button>
            </div>
          )}
          <div className="post-composer-footer">
            <div className="post-composer-actions">
              <label className="nav-icon-btn" style={{ cursor: 'pointer' }} title="Adicionar imagem">
                <span>🖼️</span>
                <input type="file" accept="image/*" style={{ display: 'none' }} onChange={handleImageSelect} />
              </label>
              <select
                value={visibility}
                onChange={(e) => setVisibility(e.target.value)}
                className="chip"
                style={{ border: 'none', background: 'var(--bg-tertiary)', padding: '4px 8px', fontSize: 12 }}
              >
                <option value="PUBLIC">🌍 Público</option>
                <option value="FOLLOWERS">👥 Seguidores</option>
                <option value="PRIVATE">🔒 Privado</option>
              </select>
            </div>
            <div className="flex items-center gap-sm">
              <span className={`char-counter ${showWarning ? 'warning' : ''} ${showDanger ? 'danger' : ''}`}>
                {remaining}
              </span>
              <button
                className="btn btn-primary btn-sm"
                disabled={isSubmitting || !content.trim() || showDanger}
                onClick={handleSubmit}
              >
                {isSubmitting ? 'Publicando...' : 'Postar'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
