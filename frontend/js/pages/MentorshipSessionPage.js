import Component from '../components/Component.js';
import { loadMentorshipDetail, loadSessions, createSession, submitFeedback } from '../services/mentorship.service.js';
import { formatFullDate, formatRelativeTime } from '../utils/format.js';
import { escapeHtml } from '../utils/helpers.js';

export default class MentorshipSessionPage extends Component {
  constructor(options = {}) {
    super(options);
    this.state = {
      mentorship: null,
      sessions: [],
      isLoading: true,
      showScheduleForm: false,
      scheduleTitle: '',
      scheduleDate: '',
      scheduleDuration: '60',
      scheduleNotes: '',
      feedbackRating: 5,
      feedbackComment: '',
      showFeedback: null,
    };
  }

  mounted() {
    this._loadData();
  }

  async _loadData() {
    const id = this.props.id;
    if (!id) return;
    try {
      const [mentorship, sessionsData] = await Promise.all([
        loadMentorshipDetail(id),
        loadSessions(id, 0).catch(() => ({ content: [] })),
      ]);
      this.state.mentorship = mentorship;
      this.state.sessions = sessionsData.content || sessionsData || [];
    } catch {}
    this.state.isLoading = false;
    this.render();
  }

  template() {
    if (this.state.isLoading) {
      return '<div class="loading-container"><div class="spinner spinner-lg"></div></div>';
    }

    const m = this.state.mentorship;
    if (!m) {
      return '<div class="empty-state"><div class="empty-state-text">Mentoria não encontrada</div></div>';
    }

    return `
      <div class="mentorship-session-page">
        <div class="page-header">
          <div class="flex items-center gap-md">
            <a href="#/mentorship" class="nav-icon-btn">←</a>
            <div>
              <h2 class="page-title">${escapeHtml(m.title || 'Mentoria')}</h2>
              <span class="text-muted" style="font-size:13px">
                ${m.mentorName ? `Mentor: ${escapeHtml(m.mentorName)}` : ''}
                ${m.menteeName ? `· Mentorando: ${escapeHtml(m.menteeName)}` : ''}
              </span>
            </div>
          </div>
        </div>

        <div style="padding:var(--spacing-md) var(--spacing-lg);border-bottom:1px solid var(--border-primary)">
          <div style="display:flex;justify-content:space-between;align-items:center">
            <h3>Sessões</h3>
            <button class="btn btn-primary btn-sm" data-schedule>Agendar sessão</button>
          </div>

          ${this.state.showScheduleForm ? this._scheduleForm() : ''}
        </div>

        <div data-sessions>
          ${this.state.sessions.length === 0
            ? '<div class="empty-state"><div class="empty-state-icon">📅</div><div class="empty-state-text">Nenhuma sessão agendada</div></div>'
            : this.state.sessions.map(s => `
              <div style="padding:var(--spacing-md) var(--spacing-lg);border-bottom:1px solid var(--border-primary)">
                <div style="display:flex;justify-content:space-between;align-items:start">
                  <div>
                    <strong>${escapeHtml(s.title || 'Sessão')}</strong>
                    <div class="text-muted" style="font-size:13px">
                      ${s.scheduledDate ? formatFullDate(s.scheduledDate) : ''}
                      ${s.duration ? `· ${s.duration}min` : ''}
                    </div>
                    ${s.notes ? `<p style="margin-top:4px;font-size:14px">${escapeHtml(s.notes)}</p>` : ''}
                  </div>
                  <div>
                    <span class="chip" style="${s.status === 'COMPLETED' ? 'background:var(--accent-success);color:#fff' : s.status === 'CANCELLED' ? 'background:var(--text-tertiary);color:#fff' : 'background:var(--accent-warning);color:#fff'}">
                      ${s.status === 'COMPLETED' ? 'Concluída' : s.status === 'CANCELLED' ? 'Cancelada' : 'Agendada'}
                    </span>
                    ${s.status === 'COMPLETED' && !s.feedback ? `<button class="btn btn-outline btn-sm mt-sm" data-give-feedback="${s.id}" style="display:block;margin-top:4px">Dar feedback</button>` : ''}
                    ${s.feedback ? '<span class="text-success" style="font-size:12px;display:block;margin-top:4px">✅ Feedback enviado</span>' : ''}
                  </div>
                </div>
              </div>
            `).join('')
          }
        </div>

        ${this.state.showFeedback ? this._feedbackForm(this.state.showFeedback) : ''}
      </div>
    `;
  }

  _scheduleForm() {
    return `
      <div style="margin-top:16px;padding:16px;background:var(--bg-secondary);border-radius:var(--radius-md)">
        <div class="form-group">
          <label>Título</label>
          <input type="text" data-schedule-title value="${escapeHtml(this.state.scheduleTitle)}" />
        </div>
        <div class="form-group">
          <label>Data e hora</label>
          <input type="datetime-local" data-schedule-date value="${this.state.scheduleDate}" />
        </div>
        <div class="form-group">
          <label>Duração (minutos)</label>
          <select data-schedule-duration>
            <option value="30" ${this.state.scheduleDuration === '30' ? 'selected' : ''}>30 min</option>
            <option value="60" ${this.state.scheduleDuration === '60' ? 'selected' : ''}>1 hora</option>
            <option value="90" ${this.state.scheduleDuration === '90' ? 'selected' : ''}>1h30</option>
            <option value="120" ${this.state.scheduleDuration === '120' ? 'selected' : ''}>2 horas</option>
          </select>
        </div>
        <div class="form-group">
          <label>Observações</label>
          <textarea data-schedule-notes style="min-height:60px">${escapeHtml(this.state.scheduleNotes)}</textarea>
        </div>
        <div class="flex gap-sm">
          <button class="btn btn-primary btn-sm" data-confirm-schedule>Agendar</button>
          <button class="btn btn-secondary btn-sm" data-cancel-schedule>Cancelar</button>
        </div>
      </div>
    `;
  }

  _feedbackForm(sessionId) {
    return `
      <div style="position:fixed;bottom:0;left:0;right:0;background:var(--bg-card);padding:var(--spacing-lg);z-index:50;box-shadow:var(--shadow-xl);border-top:1px solid var(--border-primary)">
        <h3 style="margin-bottom:8px">Feedback da Sessão</h3>
        <div class="form-group">
          <label>Avaliação</label>
          <div style="display:flex;gap:4px;font-size:24px">
            ${[1,2,3,4,5].map(n => `<span data-feedback-rating="${n}" style="cursor:pointer;${n <= this.state.feedbackRating ? '' : 'opacity:0.3'}">${n <= this.state.feedbackRating ? '⭐' : '☆'}</span>`).join('')}
          </div>
        </div>
        <div class="form-group">
          <label>Comentário</label>
          <textarea data-feedback-comment placeholder="Como foi a sessão?" style="min-height:60px"></textarea>
        </div>
        <div class="flex gap-sm">
          <button class="btn btn-primary" data-confirm-feedback="${sessionId}">Enviar Feedback</button>
          <button class="btn btn-secondary" data-cancel-feedback>Cancelar</button>
        </div>
      </div>
    `;
  }

  events() {
    return {
      'click [data-schedule]': '_toggleSchedule',
      'click [data-cancel-schedule]': '_cancelSchedule',
      'click [data-confirm-schedule]': '_confirmSchedule',
      'click [data-give-feedback]': '_showFeedback',
      'click [data-cancel-feedback]': '_cancelFeedback',
      'click [data-confirm-feedback]': '_confirmFeedback',
      'click [data-feedback-rating]': '_setRating',
      'input [data-schedule-title]': (e) => { this.state.scheduleTitle = e.target.value; },
      'input [data-schedule-date]': (e) => { this.state.scheduleDate = e.target.value; },
      'change [data-schedule-duration]': (e) => { this.state.scheduleDuration = e.target.value; },
      'input [data-schedule-notes]': (e) => { this.state.scheduleNotes = e.target.value; },
      'input [data-feedback-comment]': (e) => { this.state.feedbackComment = e.target.value; },
    };
  }

  _toggleSchedule() {
    this.state.showScheduleForm = !this.state.showScheduleForm;
    this.render();
  }

  _cancelSchedule() {
    this.state.showScheduleForm = false;
    this.render();
  }

  async _confirmSchedule() {
    const id = this.props.id;
    if (!this.state.scheduleTitle || !this.state.scheduleDate) return;
    try {
      const session = await createSession(id, {
        title: this.state.scheduleTitle,
        scheduledDate: new Date(this.state.scheduleDate).toISOString(),
        duration: parseInt(this.state.scheduleDuration),
        notes: this.state.scheduleNotes,
      });
      this.state.sessions = [...this.state.sessions, session];
      this.state.showScheduleForm = false;
      this.state.scheduleTitle = '';
      this.state.scheduleDate = '';
      this.state.scheduleNotes = '';
      this.render();
    } catch {}
  }

  _showFeedback(e) {
    this.state.showFeedback = e.currentTarget.dataset.giveFeedback;
    this.state.feedbackRating = 5;
    this.state.feedbackComment = '';
    this.render();
  }

  _cancelFeedback() {
    this.state.showFeedback = null;
    this.render();
  }

  _setRating(e) {
    this.state.feedbackRating = parseInt(e.currentTarget.dataset.feedbackRating);
    this.render();
  }

  async _confirmFeedback(e) {
    const sessionId = e.currentTarget.dataset.confirmFeedback;
    const mentorshipId = this.props.id;
    if (!sessionId) return;
    try {
      await submitFeedback(mentorshipId, sessionId, {
        rating: this.state.feedbackRating,
        comment: this.state.feedbackComment,
      });
      this.state.showFeedback = null;
      this._loadData();
    } catch {}
  }

  destroy() {
    super.destroy();
  }
}
