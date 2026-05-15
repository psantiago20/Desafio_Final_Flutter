import { useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useUI } from '../contexts/UIContext';
import { getInitials } from '../utils/helpers';

export default function ProfileEditPage() {
  const navigate = useNavigate();
  const { user, updateUser } = useAuth();
  const { addSuccessToast, addErrorToast } = useUI();

  const [form, setForm] = useState({
    name: user?.name || '',
    username: user?.username || '',
    bio: user?.bio || '',
    location: user?.location || '',
    institution: user?.institution || '',
  });
  const [avatarUrl, setAvatarUrl] = useState(user?.avatarUrl || '');
  const [bannerUrl, setBannerUrl] = useState(user?.bannerUrl || '');
  const [errors, setErrors] = useState({});
  const [isSaving, setIsSaving] = useState(false);
  const avatarInputRef = useRef(null);
  const bannerInputRef = useRef(null);

  const updateField = (field) => (e) => {
    setForm(prev => ({ ...prev, [field]: e.target.value }));
    setErrors(prev => ({ ...prev, [field]: undefined }));
  };

  const handleAvatarUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const formData = new FormData();
    formData.append('file', file);
    try {
      const res = await fetch('/api/v1/users/avatar', { method: 'POST', body: formData });
      const data = await res.json();
      setAvatarUrl(data.url);
    } catch {
      addErrorToast('Erro ao upload avatar');
    }
  };

  const handleBannerUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const formData = new FormData();
    formData.append('file', file);
    try {
      const res = await fetch('/api/v1/users/banner', { method: 'POST', body: formData });
      const data = await res.json();
      setBannerUrl(data.url);
    } catch {
      addErrorToast('Erro ao upload banner');
    }
  };

  const handleSave = async () => {
    const errs = {};
    if (!form.name.trim()) errs.name = 'Nome é obrigatório';
    if (Object.keys(errs).length) { setErrors(errs); return; }

    setIsSaving(true);
    try {
      const res = await fetch('/api/v1/users/profile', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });
      if (!res.ok) throw new Error();
      const updated = await res.json();
      updateUser({ ...updated, avatarUrl, bannerUrl });
      addSuccessToast('Perfil atualizado!');
      navigate('/profile');
    } catch {
      addErrorToast('Erro ao salvar');
      setIsSaving(false);
    }
  };

  const initials = getInitials(form.name);

  return (
    <div className="profile-page">
      <div className="page-header">
        <div className="flex items-center gap-md">
          <button className="nav-icon-btn" onClick={() => navigate('/profile')}>←</button>
          <h2 className="page-title">Editar Perfil</h2>
        </div>
      </div>

      <div className="profile-edit-form">
        <div className="banner-upload" style={{ height: 160, background: 'var(--bg-tertiary)', borderRadius: 'var(--radius-lg)', overflow: 'hidden', marginBottom: 48, position: 'relative' }}>
          {bannerUrl
            ? <img src={bannerUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
            : <div style={{ height: '100%' }}></div>
          }
          <div className="upload-overlay" onClick={() => bannerInputRef.current?.click()}>
            <span>📷 Alterar banner</span>
          </div>
          <input type="file" accept="image/*" ref={bannerInputRef} style={{ display: 'none' }} onChange={handleBannerUpload} />
        </div>

        <div className="avatar-upload" style={{ width: 96, height: 96, margin: '-72px 0 16px 16px', position: 'relative', border: '4px solid var(--bg-primary)', borderRadius: '50%' }}>
          {avatarUrl
            ? <img src={avatarUrl} alt="" style={{ width: '100%', height: '100%', borderRadius: '50%', objectFit: 'cover' }} />
            : <div className="avatar avatar-xl avatar-placeholder" style={{ fontSize: 32 }}>{initials}</div>
          }
          <div className="upload-overlay" style={{ borderRadius: '50%' }} onClick={() => avatarInputRef.current?.click()}>
            <span>📷</span>
          </div>
          <input type="file" accept="image/*" ref={avatarInputRef} style={{ display: 'none' }} onChange={handleAvatarUpload} />
        </div>

        <div className="form-group">
          <label>Nome</label>
          <input type="text" value={form.name} onChange={updateField('name')} />
          {errors.name && <div className="form-error">{errors.name}</div>}
        </div>
        <div className="form-group">
          <label>Nome de usuário</label>
          <input type="text" value={form.username} onChange={updateField('username')} />
        </div>
        <div className="form-group">
          <label>Bio</label>
          <textarea value={form.bio} onChange={updateField('bio')} maxLength={500} />
        </div>
        <div className="form-group">
          <label>Localização</label>
          <input type="text" value={form.location} onChange={updateField('location')} />
        </div>
        <div className="form-group">
          <label>Instituição</label>
          <input type="text" value={form.institution} onChange={updateField('institution')} />
        </div>

        <div className="flex gap-md" style={{ marginTop: 24 }}>
          <button className="btn btn-primary" disabled={isSaving} onClick={handleSave}>
            {isSaving ? 'Salvando...' : 'Salvar'}
          </button>
          <button className="btn btn-secondary" onClick={() => navigate('/profile')}>Cancelar</button>
        </div>
      </div>
    </div>
  );
}
