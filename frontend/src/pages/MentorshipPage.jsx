import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import Modal from '../components/Modal';
import LoadingSpinner from '../components/LoadingSpinner';
import { getMentorshipsApi, getAvailableMentorsApi, createMentorshipApi, applyForMentorshipApi } from '../api/mentorship.api';
import { formatRelativeTime } from '../utils/format';
import { escapeHtml } from '../utils/helpers';
import { useUI } from '../contexts/UIContext';

export default function MentorshipPage() {
  const navigate = useNavigate();
  const { addSuccessToast, addErrorToast } = useUI();
  const [tab, setTab] = useState('my');
  const [mentorships, setMentorships] = useState([]);
  const [available, setAvailable] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showRequestModal, setShowRequestModal] = useState(false);

  useEffect(() => {
    async function load() {
      setIsLoading(true);
      try {
        const [myData, availData] = await Promise.all([
          getMentorshipsApi({ page: 0, size: 20 }).catch(() => ({ content: [] })),
          getAvailableMentorsApi().catch(() => ({ content: [] })),
        ]);
        setMentorships(myData.content || myData || []);
        setAvailable(availData.content || availData || []);
      } catch {}
      setIsLoading(false);
    }
    load();
  }, []);

  const handleRequest = async ({ title, description, area }) => {
    if (!title?.trim()) return;
    try {
      const newM = await createMentorshipApi({ title, description, area });
      setMentorships(prev => [newM, ...prev]);
      setShowRequestModal(false);
      addSuccessToast('Solicitação enviada!');
    } catch { addErrorToast('Erro ao solicitar mentoria'); }
  };

  const handleApply = async (id) => {
    try {
      await applyForMentorshipApi(id);
      addSuccessToast('Solicitação enviada!');
    } catch { addErrorToast('Erro ao solicitar'); }
  };

  const statusLabels = { PENDING: 'Pendente', ACTIVE: 'Ativa', COMPLETED: 'Concluída', CANCELLED: 'Cancelada' };
  const statusColors = {
    PENDING: 'var(--accent-warning)', ACTIVE: 'var(--accent-success)',
    COMPLETED: 'var(--accent-primary)', CANCELLED: 'var(--text-tertiary)',
  };

  return (
    <div className="mentorship-page">
      <div className="page-header">
        <div className="flex items-center justify-between">
          <h2 className="page-title">Mentorias</h2>
          <button className="btn btn-primary btn-sm" onClick={() => setShowRequestModal(true)}>+ Solicitar</button>
        </div>
      </div>

      <div className="tabs">
        <div className={`tab ${tab === 'my' ? 'active' : ''}`} onClick={() => setTab('my')}>Minhas Mentorias</div>
        <div className={`tab ${tab === 'available' ? 'active' : ''}`} onClick={() => setTab('available')}>Mentores Disponíveis</div>
      </div>

      {isLoading ? <LoadingSpinner size="lg" /> : tab === 'my' ? (
        mentorships.length === 0
          ? <div className="empty-state"><div className="empty-state-icon">🎓</div><div className="empty-state-text">Nenhuma mentoria ativa</div></div>
          : mentorships.map(m => (
              <div key={m.id} className="group-card" onClick={() => navigate(`/mentorship/${m.id}`)} style={{ cursor: 'pointer' }}>
                <div style={{ flex: 1 }}>
                  <div className="group-card-name">
                    <a href={`/mentorship/${m.id}`}>{escapeHtml(m.title || 'Mentoria')}</a>
                  </div>
                  <div className="group-card-meta">
                    {m.mentorName && `Mentor: ${escapeHtml(m.mentorName)}`}
                    {m.menteeName && `· Mentorando: ${escapeHtml(m.menteeName)}`}
                  </div>
                  <div className="group-card-desc">{escapeHtml(m.description || '')}</div>
                  <div className="flex gap-sm" style={{ marginTop: 8 }}>
                    <span className="chip" style={{ background: statusColors[m.status] || 'var(--bg-tertiary)', color: '#fff' }}>
                      {statusLabels[m.status] || m.status || 'Pendente'}
                    </span>
                    {m.createdAt && <span className="text-muted" style={{ fontSize: 12 }}>{formatRelativeTime(m.createdAt)}</span>}
                  </div>
                </div>
              </div>
            ))
      ) : (
        available.length === 0
          ? <div className="empty-state"><div className="empty-state-icon">🎓</div><div className="empty-state-text">Nenhum mentor disponível</div></div>
          : available.map(m => (
              <div key={m.id} className="group-card">
                <div style={{ flex: 1 }}>
                  <div className="group-card-name">{escapeHtml(m.name || m.fullName || '')}</div>
                  <div className="group-card-meta">{m.expertise ? escapeHtml(m.expertise) : ''}</div>
                  <div className="group-card-desc">{escapeHtml(m.bio || m.description || '')}</div>
                  <button className="btn btn-primary btn-sm mt-sm" onClick={() => handleApply(m.id)}>Solicitar Mentoria</button>
                </div>
              </div>
            ))
      )}

      {showRequestModal && (
        <RequestModal
          onClose={() => setShowRequestModal(false)}
          onSubmit={handleRequest}
        />
      )}
    </div>
  );
}

function RequestModal({ onClose, onSubmit }) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [area, setArea] = useState('');

  return (
    <Modal
      title="Solicitar Mentoria"
      onClose={onClose}
      showClose
      footer={
        <>
          <button className="btn btn-secondary" onClick={onClose}>Cancelar</button>
          <button className="btn btn-primary" onClick={() => onSubmit({ title, description, area })}>Solicitar</button>
        </>
      }
      content={
        <>
          <div className="form-group">
            <label>Título</label>
            <input type="text" placeholder="Ex: Ajuda com Matemática" value={title} onChange={(e) => setTitle(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Descrição</label>
            <textarea placeholder="Descreva o que você busca..." style={{ minHeight: 80 }} value={description} onChange={(e) => setDescription(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Área de interesse</label>
            <input type="text" placeholder="Ex: Ciência da Computação" value={area} onChange={(e) => setArea(e.target.value)} />
          </div>
        </>
      }
    />
  );
}
