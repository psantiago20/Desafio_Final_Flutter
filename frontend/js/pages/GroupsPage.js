import Component from '../components/Component.js';
import GroupCard from '../components/GroupCard.js';
import InfiniteScroll from '../components/InfiniteScroll.js';
import Modal from '../components/Modal.js';
import { loadGroups, joinGroup, leaveGroup, createGroup, searchGroups } from '../services/group.service.js';
import { escapeHtml } from '../utils/helpers.js';

export default class GroupsPage extends Component {
  constructor(options = {}) {
    super(options);
    this.state = {
      groups: [],
      isLoading: true,
      page: 0,
      hasMore: true,
      searchQuery: '',
      selectedCategory: '',
      showCreateModal: false,
      createName: '',
      createDescription: '',
      createCategory: '',
    };
    this._groupCardInstances = [];
    this._modal = null;
  }

  mounted() {
    this._loadGroups();
  }

  async _loadGroups() {
    this.state.isLoading = true;
    this.render();
    try {
      const data = await loadGroups(0);
      this.state.groups = data.content || data || [];
      this.state.hasMore = data.last === false || (!Array.isArray(data) && data.length === 20);
    } catch {
      this.state.groups = [];
    } finally {
      this.state.isLoading = false;
      this.render();
    }
  }

  template() {
    const { groups, isLoading, searchQuery, selectedCategory, showCreateModal } = this.state;

    const categories = ['', 'Tecnologia', 'Ciência', 'Artes', 'Esportes', 'Música', 'Acadêmico'];

    return `
      <div class="groups-page">
        <div class="page-header">
          <div class="flex items-center justify-between">
            <h2 class="page-title">Grupos</h2>
            <button class="btn btn-primary btn-sm" data-create-group>+ Criar</button>
          </div>
          <div class="search-bar mt-sm">
            <span class="search-icon">🔍</span>
            <input type="search" placeholder="Buscar grupos..." data-search-input value="${escapeHtml(searchQuery)}" />
          </div>
        </div>

        <div style="padding:var(--spacing-sm) var(--spacing-lg);display:flex;gap:8px;flex-wrap:wrap;border-bottom:1px solid var(--border-primary)">
          ${categories.map(c => `
            <span class="chip ${selectedCategory === c ? 'chip-active' : ''}" data-category="${c}">${c || 'Todos'}</span>
          `).join('')}
        </div>

        ${isLoading
          ? '<div class="loading-container"><div class="spinner spinner-lg"></div></div>'
          : groups.length === 0
            ? '<div class="empty-state"><div class="empty-state-icon">👥</div><div class="empty-state-text">Nenhum grupo encontrado</div></div>'
            : `<div data-groups-list>
                ${groups.map((g, i) => `<div data-group-slot="${i}"></div>`).join('')}
              </div>`
        }
        <div data-scroll-sentinel></div>
      </div>
    `;
  }

  updated() {
    this._renderGroupCards();
    this._setupInfiniteScroll();
    if (this.state.showCreateModal) this._showCreateModal();
  }

  _renderGroupCards() {
    for (const inst of this._groupCardInstances) inst.destroy();
    this._groupCardInstances = [];

    const parent = this.container?.querySelector('[data-groups-list]');
    if (!parent) return;

    this.state.groups.forEach((group, idx) => {
      const slot = parent.querySelector(`[data-group-slot="${idx}"]`);
      if (!slot) return;
      const card = new GroupCard({
        container: slot,
        props: { group, onAction: (groupId) => this._handleGroupAction(groupId) },
      });
      card.mount(slot);
      this._groupCardInstances.push(card);
    });
  }

  _setupInfiniteScroll() {
    if (this._scroll) this._scroll.destroy();
    const sentinel = this.container?.querySelector('[data-scroll-sentinel]');
    if (!sentinel) return;
    this._scroll = new InfiniteScroll({
      container: this.container,
      props: { sentinel, onLoad: () => this._loadMore() },
    });
    this._scroll.mount(this.container);
  }

  async _loadMore() {
    if (!this.state.hasMore) return;
    this.state.page++;
    try {
      const data = await loadGroups(this.state.page);
      const newGroups = data.content || data || [];
      this.state.groups = [...this.state.groups, ...newGroups];
      this.state.hasMore = data.last === false;
      this.render();
    } catch {
      this.state.page--;
    }
  }

  async _handleGroupAction(groupId) {
    const group = this.state.groups.find(g => g.id === groupId);
    if (!group) return;
    try {
      if (group.isMember) {
        await leaveGroup(groupId);
        group.isMember = false;
        group.memberCount--;
      } else {
        await joinGroup(groupId);
        group.isMember = true;
        group.memberCount++;
      }
      this.render();
    } catch {}
  }

  events() {
    return {
      'click [data-create-group]': '_toggleCreateModal',
      'click [data-category]': '_filterCategory',
      'input [data-search-input]': '_handleSearch',
    };
  }

  _filterCategory(e) {
    this.state.selectedCategory = e.currentTarget.dataset.category;
    this.state.groups = [];
    this.state.page = 0;
    this.state.hasMore = true;
    this._loadGroups();
  }

  _handleSearch(e) {
    this.state.searchQuery = e.target.value;
  }

  _toggleCreateModal() {
    this.state.showCreateModal = !this.state.showCreateModal;
    this.render();
  }

  _showCreateModal() {
    const modalRoot = document.getElementById('modal-root');
    if (!modalRoot) return;

    if (this._modal) this._modal.destroy();

    const contentHtml = `
      <div class="form-group">
        <label>Nome do grupo</label>
        <input type="text" data-create-name placeholder="Nome do grupo" />
      </div>
      <div class="form-group">
        <label>Descrição</label>
        <textarea data-create-desc placeholder="Descrição do grupo" style="min-height:80px"></textarea>
      </div>
      <div class="form-group">
        <label>Categoria</label>
        <select data-create-category>
          <option value="">Selecione</option>
          <option value="Tecnologia">Tecnologia</option>
          <option value="Ciência">Ciência</option>
          <option value="Artes">Artes</option>
          <option value="Esportes">Esportes</option>
          <option value="Música">Música</option>
          <option value="Acadêmico">Acadêmico</option>
        </select>
      </div>
    `;

    const footerHtml = `
      <button class="btn btn-secondary" data-modal-cancel>Cancelar</button>
      <button class="btn btn-primary" data-modal-confirm>Criar</button>
    `;

    this._modal = new Modal({
      container: modalRoot,
      props: {
        title: 'Criar Grupo',
        content: contentHtml,
        footer: footerHtml,
        onClose: () => this._closeCreateModal(),
      },
    });
    this._modal.mount(modalRoot);

    const confirmBtn = modalRoot.querySelector('[data-modal-confirm]');
    const cancelBtn = modalRoot.querySelector('[data-modal-cancel]');
    if (confirmBtn) confirmBtn.addEventListener('click', () => this._confirmCreate());
    if (cancelBtn) cancelBtn.addEventListener('click', () => this._closeCreateModal());
  }

  async _confirmCreate() {
    const modalRoot = document.getElementById('modal-root');
    const name = modalRoot?.querySelector('[data-create-name]')?.value;
    const description = modalRoot?.querySelector('[data-create-desc]')?.value;
    const category = modalRoot?.querySelector('[data-create-category]')?.value;

    if (!name?.trim()) return;

    try {
      const newGroup = await createGroup({ name, description, category });
      this.state.groups = [newGroup, ...this.state.groups];
      this._closeCreateModal();
      this.render();
    } catch {}
  }

  _closeCreateModal() {
    this.state.showCreateModal = false;
    if (this._modal) {
      this._modal.destroy();
      this._modal = null;
    }
    const modalRoot = document.getElementById('modal-root');
    if (modalRoot) modalRoot.innerHTML = '';
  }

  destroy() {
    for (const inst of this._groupCardInstances) inst.destroy();
    if (this._scroll) this._scroll.destroy();
    if (this._modal) this._modal.destroy();
    super.destroy();
  }
}
