import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import LoadingSpinner from '../components/LoadingSpinner';
import { getMentorshipByIdApi, getMentorshipSessionsApi, createSessionApi, submitSessionFeedbackApi } from '../api/mentorship.api';
import { formatFullDate, formatRelativeTime } from '../utils/format';
import { escapeHtml } from '../utils/helpers';
import { useUI } from '../contexts/UIContext';

export default function MentorshipSessionPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { addSuccessToast, addErrorToast } = useUI();
  const [mentorship, setMentorship] = useState(null);
  const [sessions, setSessions] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showScheduleForm, setShowScheduleForm] = useState(false);
  const [schedule, setSchedule] = useState({ title: '', date: '', duration: '60', notes: '' });
  const [feedback, setFeedback] = useState({ sessionId: null, rating: 5, comment: '' });

  useEffect(() => {
    async function load() {
      setIsLoading(true);
      try {
        const [m, sData] = await Promise.all([
          getMentorshipByIdApi(id),
          getMentorshipSessionsApi(id, { page: 0, size: 20 }).catch(() => ({ content: [] })),
        ]);
        setMentorship(m);
        setSessions(sData.content || sData || []);
      } catch {}
      setIsLoading(false);
    }
    load();
  }, [id]);

  const handleSchedule = async () => {
    if (!schedule.title || !schedule.date) return;
    try {
      const session = await createSessionApi(id, {
        title: schedule.title,
        scheduledDate: new Date(schedule.date).toISOString(),
        duration: parseInt(schedule.duration),
        notes: schedule.notes,
      });
      setSessions(prev => [...prev, session]);
      setShowScheduleForm(false);
      setSchedule({ title: '', date: '', duration: '60', notes: '' });
      addSuccessToast('Sessão agendada!');
    } catch { addErrorToast('Erro ao agendar'); }
  };

  const handleFeedback = async () => {
    if (!feedback.sessionId) return;
    try {
      await submitSessionFeedbackApi(id, feedback.sessionId, {
        rating: feedback.rating,
        comment: feedback.comment,
      });
      setFeedback({ sessionId: null, rating: 5, comment: '' });
      addSuccessToast('Feedback enviado!');
    } catch { addErrorToast('Erro ao enviar feedback'); }
  };

  if (isLoading) return <LoadingSpinner size="lg" />;
  if (!mentorship) return <div className="empty-state"><div className="empty-state-text">Mentoria não encontrada</div></div>;

  return (
    <div className="mentorship-session-page">
      <div className="page-header">
        <div className="flex items-center gap-md">
          <button className="nav-icon-btn" onClick={() => navigate('/mentorship')}>←</button>
          <div>
            <h2 className="page-title">{escapeHtml(mentorship.title || 'Mentoria')}</h2>
            <span className="text-muted" style={{ fontSize: 13 }}>
              {mentorship.mentorName && `Mentor: ${escapeHtml(mentorship.mentorName)}`}
              {mentorship.menteeName && `· Mentorando: ${escapeHtml(mentorship.menteeName)}`}
            </span>
          </div>
        </div>
      </div>

      <div style={{ padding: 'var(--spacing-md) var(--spacing-lg)', borderBottom: '1px solid var(--border-primary)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h3>Sessões</h3>
          <button className="btn btn-primary btn-sm" onClick={() => setShowScheduleForm(!showScheduleForm)}>
            Agendar sessão
          </button>
        </div>

        {showScheduleForm && (
          <div style={{ marginTop: 16, padding: 16, background: 'var(--bg-secondary)', borderRadius: 'var(--radius-md)' }}>
            <div className="form-group">
              <label>Título</label>
              <input type="text" value={schedule.title} onChange={(e) => setSchedule(s => ({ ...s, title: e.target.value }))} />
            </div>
            <div className="form-group">
              <label>Data e hora</label>
              <input type="datetime-local" value={schedule.date} onChange={(e) => setSchedule(s => ({ ...s, date: e.target.value }))} />
            </div>
            <div className="form-group">
              <label>Duração (minutos)</label>
              <select value={schedule.duration} onChange={(e) => setSchedule(s => ({ ...s, duration: e.target.value }))}>
                <option value="30">30 min</option>
                <option value="60">1 hora</option>
                <option value="90">1h30</option>
                <option value="120">2 horas</option>
              </select>
            </div>
            <div className="form-group">
              <label>Observações</label>
              <textarea style={{ minHeight: 60 }} value={schedule.notes} onChange={(e) => setSchedule(s => ({ ...s, notes: e.target.value }))} />
            </div>
            <div className="flex gap-sm">
              <button className="btn btn-primary btn-sm" onClick={handleSchedule}>Agendar</button>
              <button className="btn btn-secondary btn-sm" onClick={() => setShowScheduleForm(false)}>Cancelar</button>
            </div>
          </div>
        )}
      </div>

      <div>
        {sessions.length === 0
          ? <div className="empty-state"><div className="empty-state-icon">📅</div><div className="empty-state-text">Nenhuma sessão agendada</div></div>
          : sessions.map(s => (
              <div key={s.id} style={{ padding: 'var(--spacing-md) var(--spacing-lg)', borderBottom: '1px solid var(--border-secondary)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                  <div>
                    <strong>{escapeHtml(s.title || 'Sessão')}</strong>
                    <div className="text-muted" style={{ fontSize: 13 }}>
                      {s.scheduledDate ? formatFullDate(s.scheduledDate) : ''}
                      {s.duration ? `· ${s.duration}min` : ''}
                    </div>
                    {s.notes && <p style={{ marginTop: 4, fontSize: 14 }}>{escapeHtml(s.notes)}</p>}
                  </div>
                  <div>
                    <span className="chip" style={{
                      background: s.status === 'COMPLETED' ? 'var(--accent-success)' : s.status === 'CANCELLED' ? 'var(--text-tertiary)' : 'var(--accent-warning)',
                      color: '#fff',
                    }}>
                      {s.status === 'COMPLETED' ? 'Concluída' : s.status === 'CANCELLED' ? 'Cancelada' : 'Agendada'}
                    </span>
                    {s.status === 'COMPLETED' && !s.feedback && (
                      <button className="btn btn-outline btn-sm mt-sm" style={{ display: 'block', marginTop: 4 }}
                        onClick={() => setFeedback({ sessionId: s.id, rating: 5, comment: '' })}>
                        Dar feedback
                      </button>
                    )}
                    {s.feedback && <span className="text-success" style={{ fontSize: 12, display: 'block', marginTop: 4 }}>✅ Feedback enviado</span>}
                  </div>
                </div>
              </div>
            ))
        }
      </div>

      {feedback.sessionId && (
        <div style={{
          position: 'fixed', bottom: 0, left: 0, right: 0,
          background: 'var(--bg-card)', padding: 'var(--spacing-lg)',
          zIndex: 50, boxShadow: 'var(--shadow-xl)',
          borderTop: '1px solid var(--border-primary)',
        }}>
          <h3 style={{ marginBottom: 8 }}>Feedback da Sessão</h3>
          <div className="form-group">
            <label>Avaliação</label>
            <div style={{ display: 'flex', gap: 4, fontSize: 24 }}>
              {[1, 2, 3, 4, 5].map(n => (
                <span key={n} style={{ cursor: 'pointer', opacity: n <= feedback.rating ? 1 : 0.3 }}
                  onClick={() => setFeedback(f => ({ ...f, rating: n }))}>
                  {n <= feedback.rating ? '⭐' : '☆'}
                </span>
              ))}
            </div>
          </div>
          <div className="form-group">
            <label>Comentário</label>
            <textarea placeholder="Como foi a sessão?" style={{ minHeight: 60 }}
              value={feedback.comment}
              onChange={(e) => setFeedback(f => ({ ...f, comment: e.target.value }))} />
          </div>
          <div className="flex gap-sm">
            <button className="btn btn-primary" onClick={handleFeedback}>Enviar Feedback</button>
            <button className="btn btn-secondary" onClick={() => setFeedback({ sessionId: null, rating: 5, comment: '' })}>Cancelar</button>
          </div>
        </div>
      )}
    </div>
  );
}
