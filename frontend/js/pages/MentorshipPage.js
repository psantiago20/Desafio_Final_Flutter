import Component from '../components/Component.js';
import { loadMentorships, loadAvailableMentors, applyForMentorship, createMentorship } from '../services/mentorship.service.js';
import { formatRelativeTime } from '../utils/format.js';
import { escapeHtml } from '../utils/helpers.js';
import Modal from '../components/Modal.js';
import { MENTORSHIP_STATUS } from '../constants/config.js';

export default class MentorshipPage extends Component {
  constructor(options = {}) {
    super(options);
    this.state = {
      tab: 'my',
      mentorships: [],
      available: [],
      isLoading: true,
      showRequestModal: false,
    };
    this._modal = null;
  }

  mounted() {
    this._loadData();
  }

  async _loadData() {
    this.state.isLoading = true;
    this.render();
    try {
      const [myData, availData] = await Promise.all([
        loadMentorships(0).catch(() => ({ content: [] })),
        loadAvailableMentors(0).catch(() => ({ content: [] })),
      ]);
      this.state.mentorships = myData.content || myData || [];
      this.state.available = availData.content || availData || [];
    } catch {
    } finally {
      this.state.isLoading = false;
      this.render();
    }
  }

  template() {
    const { tab, mentorships, available, isLoading } = this.state;

    return `
      <div class="mentorship-page">
        <div class="page-header">
          <div class="flex items-center justify-between">
            <h2 class="page-title">Mentorias</h2>
            <button class="btn btn-primary btn-sm" data-request-mentorship>+ Solicitar</button>
          </div>
        </div>

        <div class="tabs">
          <div class="tab ${tab === 'my' ? 'active' : ''}" data-tab="my">Minhas Mentorias</div>
          <div class="tab ${tab === 'available' ? 'active' : ''}" data-tab="available">Mentores Disponíveis</div>
        </div>

        ${isLoading
          ? '<div class="loading-container"><div class="spinner spinner-lg"></div></div>'
          : tab === 'my'
            ? this._renderMyMentorships()
            : this._renderAvailable()
        }
      </div>
    `;
  }

  _renderMyMentorships() {
    const items = this.state.mentorships;
    if (!items.length) {
      return '<div class="empty-state"><div class="empty-state-icon">🎓</div><div class="empty-state-text">Nenhuma mentoria ativa</div></div>';
    }

    const statusLabels = { PENDING: 'Pendente', ACTIVE: 'Ativa', COMPLETED: 'Concluída', CANCELLED: 'Cancelada' };
    const statusColors = { PENDING: 'var(--accent-warning)', ACTIVE: 'var(--accent-success)', COMPLETED: 'var(--accent-primary)', CANCELLED: 'var(--text-tertiary)' };

    return items.map(m => `
      <div class="group-card" data-mentorship-id="${m.id}">
        <div style="flex:1">
          <div class="group-card-name">
            <a href="#/mentorship/${m.id}">${escapeHtml(m.title || 'Mentoria')}</a>
          </div>
          <div class="group-card-meta">
            ${m.mentorName ? `Mentor: ${escapeHtml(m.mentorName)}` : ''}
            ${m.menteeName ? `· Mentorando: ${escapeHtml(m.menteeName)}` : ''}
          </div>
          <div class="group-card-desc">${escapeHtml(m.description || '')}</div>
          <div class="flex gap-sm" style="margin-top:8px">
            <span class="chip" style="background:${statusColors[m.status] || 'var(--bg-tertiary)'};color:#fff">
              ${statusLabels[m.status] || m.status || 'Pendente'}
            </span>
            ${m.createdAt ? `<span class="text-muted" style="font-size:12px">${formatRelativeTime(m.createdAt)}</span>` : ''}
          </div>
        </div>
      </div>
    `).join('');
  }

  _renderAvailable() {
    const items = this.state.available;
    if (!items.length) {
      return '<div class="empty-state"><div class="empty-state-icon">🎓</div><div class="empty-state-text">Nenhum mentor disponível no momento</div></div>';
    }

    return items.map(m => `
      <div class="group-card">
        <div style="flex:1">
          <div class="group-card-name">${escapeHtml(m.name || m.fullName || '')}</div>
          <div class="group-card-meta">${m.expertise ? escapeHtml(m.expertise) : ''}</div>
          <div class="group-card-desc">${escapeHtml(m.bio || m.description || '')}</div>
          <button class="btn btn-primary btn-sm mt-sm" data-apply-mentor="${m.id}">Solicitar Mentoria</button>
        </div>
      </div>
    `).join('');
  }

  events() {
    return {
      'click [data-tab]': '_switchTab',
      'click [data-request-mentorship]': '_showRequestForm',
      'click [data-apply-mentor]': '_handleApply',
    };
  }

  _switchTab(e) {
    this.state.tab = e.currentTarget.dataset.tab;
    this.render();
  }

  _showRequestForm() {
    const modalRoot = document.getElementById('modal-root');
    if (!modalRoot) return;

    this._modal = new Modal({
      container: modalRoot,
      props: {
        title: 'Solicitar Mentoria',
        content: `
          <div class="form-group">
            <label>Título</label>
            <input type="text" data-request-title placeholder="Ex: Ajuda com Matemática" />
          </div>
          <div class="form-group">
            <label>Descrição</label>
            <textarea data-request-desc placeholder="Descreva o que você busca..." style="min-height:80px"></textarea>
          </div>
          <div class="form-group">
            <label>Área de interesse</label>
            <input type="text" data-request-area placeholder="Ex: Ciência da Computação" />
          </div>
        `,
        footer: `
          <button class="btn btn-secondary" data-cancel-request>Cancelar</button>
          <button class="btn btn-primary" data-confirm-request>Solicitar</button>
        `,
        onClose: () => this._closeModal(),
      },
    });
    this._modal.mount(modalRoot);

    const confirm = modalRoot.querySelector('[data-confirm-request]');
    const cancel = modalRoot.querySelector('[data-cancel-request]');
    if (confirm) confirm.addEventListener('click', () => this._confirmRequest());
    if (cancel) cancel.addEventListener('click', () => this._closeModal());
  }

  async _confirmRequest() {
    const modalRoot = document.getElementById('modal-root');
    const title = modalRoot?.querySelector('[data-request-title]')?.value;
    const description = modalRoot?.querySelector('[data-request-desc]')?.value;
    const area = modalRoot?.querySelector('[data-request-area]')?.value;

    if (!title?.trim()) return;

    try {
      const newM = await createMentorship({ title, description, area });
      this.state.mentorships = [newM, ...this.state.mentorships];
      this.render();
    } catch {}
    this._closeModal();
  }

  async _handleApply(e) {
    const id = e.currentTarget.dataset.applyMentor;
    if (!id) return;
    try {
      await applyForMentorship(id);
    } catch {}
  }

  _closeModal() {
    if (this._modal) { this._modal.destroy(); this._modal = null; }
    const modalRoot = document.getElementById('modal-root');
    if (modalRoot) modalRoot.innerHTML = '';
  }

  destroy() {
    if (this._modal) this._modal.destroy();
    super.destroy();
  }
}
