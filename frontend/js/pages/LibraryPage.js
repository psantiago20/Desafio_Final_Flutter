import Component from '../components/Component.js';
import MaterialCard from '../components/MaterialCard.js';
import InfiniteScroll from '../components/InfiniteScroll.js';
import Modal from '../components/Modal.js';
import { loadLibrary, searchLibrary, createLibraryItem } from '../services/library.service.js';
import { escapeHtml } from '../utils/helpers.js';

export default class LibraryPage extends Component {
  constructor(options = {}) {
    super(options);
    this.state = {
      materials: [],
      isLoading: true,
      page: 0,
      hasMore: true,
      searchQuery: '',
      typeFilter: '',
      showUploadModal: false,
      uploadTitle: '',
      uploadDescription: '',
      uploadType: 'PDF',
      uploadUrl: '',
      uploadTags: '',
    };
    this._materialInstances = [];
    this._modal = null;
  }

  mounted() {
    this._loadMaterials();
  }

  async _loadMaterials() {
    this.state.isLoading = true;
    this.render();
    try {
      const data = this.state.searchQuery
        ? await searchLibrary(this.state.searchQuery, this.state.typeFilter, 0)
        : await loadLibrary(0);
      this.state.materials = data.content || data || [];
      this.state.hasMore = data.last === false;
    } catch {
      this.state.materials = [];
    } finally {
      this.state.isLoading = false;
      this.render();
    }
  }

  template() {
    const { materials, isLoading, searchQuery, typeFilter } = this.state;
    const types = ['', 'PDF', 'VIDEO', 'LINK', 'DOCUMENT'];
    const typeLabels = { '': 'Todos', PDF: '📄 PDF', VIDEO: '🎬 Vídeo', LINK: '🔗 Link', DOCUMENT: '📝 Documento' };

    return `
      <div class="library-page">
        <div class="page-header">
          <div class="flex items-center justify-between">
            <h2 class="page-title">Biblioteca</h2>
            <button class="btn btn-primary btn-sm" data-upload>+ Upload</button>
          </div>
          <div class="search-bar mt-sm">
            <span class="search-icon">🔍</span>
            <input type="search" placeholder="Buscar materiais..." data-search-input value="${escapeHtml(searchQuery)}" />
          </div>
        </div>

        <div style="padding:var(--spacing-sm) var(--spacing-lg);display:flex;gap:8px;flex-wrap:wrap;border-bottom:1px solid var(--border-primary)">
          ${types.map(t => `
            <span class="chip ${typeFilter === t ? 'chip-active' : ''}" data-type-filter="${t}">${typeLabels[t] || t}</span>
          `).join('')}
        </div>

        ${isLoading
          ? '<div class="loading-container"><div class="spinner spinner-lg"></div></div>'
          : materials.length === 0
            ? '<div class="empty-state"><div class="empty-state-icon">📚</div><div class="empty-state-text">Nenhum material encontrado</div></div>'
            : `<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:8px;padding:var(--spacing-md)">
                ${materials.map((m, i) => `<div data-material-slot="${i}"></div>`).join('')}
              </div>`
        }
        <div data-scroll-sentinel></div>
      </div>
    `;
  }

  updated() {
    this._renderMaterials();
    this._setupInfiniteScroll();
  }

  _renderMaterials() {
    for (const inst of this._materialInstances) inst.destroy();
    this._materialInstances = [];

    const parent = this.container?.querySelector('[data-material-slot]')?.parentNode;
    if (!parent) return;

    this.state.materials.forEach((mat, idx) => {
      const slot = parent.querySelector(`[data-material-slot="${idx}"]`);
      if (!slot) return;
      const card = new MaterialCard({ container: slot, props: { item: mat } });
      card.mount(slot);
      this._materialInstances.push(card);
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
      const data = this.state.searchQuery
        ? await searchLibrary(this.state.searchQuery, this.state.typeFilter, this.state.page)
        : await loadLibrary(this.state.page);
      const newItems = data.content || data || [];
      this.state.materials = [...this.state.materials, ...newItems];
      this.state.hasMore = data.last === false;
      this.render();
    } catch { this.state.page--; }
  }

  events() {
    return {
      'input [data-search-input]': '_handleSearch',
      'click [data-type-filter]': '_filterType',
      'click [data-upload]': '_toggleUpload',
    };
  }

  _handleSearch(e) {
    this.state.searchQuery = e.target.value;
    this.state.page = 0;
    this._loadMaterials();
  }

  _filterType(e) {
    this.state.typeFilter = e.currentTarget.dataset.typeFilter;
    this.state.page = 0;
    this._loadMaterials();
  }

  _toggleUpload() {
    this.state.showUploadModal = !this.state.showUploadModal;
    if (this.state.showUploadModal) this._showUploadModal();
  }

  _showUploadModal() {
    const modalRoot = document.getElementById('modal-root');
    if (!modalRoot) return;
    if (this._modal) this._modal.destroy();

    this._modal = new Modal({
      container: modalRoot,
      props: {
        title: 'Adicionar Material',
        content: `
          <div class="form-group">
            <label>Título</label>
            <input type="text" data-upload-title placeholder="Título do material" />
          </div>
          <div class="form-group">
            <label>Descrição</label>
            <textarea data-upload-desc placeholder="Descrição" style="min-height:60px"></textarea>
          </div>
          <div class="form-group">
            <label>Tipo</label>
            <select data-upload-type>
              <option value="PDF">PDF</option>
              <option value="VIDEO">Vídeo</option>
              <option value="LINK">Link</option>
              <option value="DOCUMENT">Documento</option>
            </select>
          </div>
          <div class="form-group">
            <label>URL</label>
            <input type="url" data-upload-url placeholder="https://..." />
          </div>
          <div class="form-group">
            <label>Tags (separadas por vírgula)</label>
            <input type="text" data-upload-tags placeholder="tag1, tag2, tag3" />
          </div>
        `,
        footer: `
          <button class="btn btn-secondary" data-modal-cancel>Cancelar</button>
          <button class="btn btn-primary" data-modal-confirm>Adicionar</button>
        `,
        onClose: () => this._closeUpload(),
      },
    });
    this._modal.mount(modalRoot);

    const confirm = modalRoot.querySelector('[data-modal-confirm]');
    const cancel = modalRoot.querySelector('[data-modal-cancel]');
    if (confirm) confirm.addEventListener('click', () => this._confirmUpload());
    if (cancel) cancel.addEventListener('click', () => this._closeUpload());
  }

  async _confirmUpload() {
    const modalRoot = document.getElementById('modal-root');
    const title = modalRoot?.querySelector('[data-upload-title]')?.value;
    const description = modalRoot?.querySelector('[data-upload-desc]')?.value;
    const type = modalRoot?.querySelector('[data-upload-type]')?.value;
    const url = modalRoot?.querySelector('[data-upload-url]')?.value;
    const tags = modalRoot?.querySelector('[data-upload-tags]')?.value;

    if (!title?.trim()) return;

    try {
      const item = await createLibraryItem({
        title, description, type, url,
        tags: tags ? tags.split(',').map(t => t.trim()).filter(Boolean) : [],
      });
      this.state.materials = [item, ...this.state.materials];
      this._closeUpload();
      this.render();
    } catch {}
  }

  _closeUpload() {
    this.state.showUploadModal = false;
    if (this._modal) { this._modal.destroy(); this._modal = null; }
    const modalRoot = document.getElementById('modal-root');
    if (modalRoot) modalRoot.innerHTML = '';
  }

  destroy() {
    for (const inst of this._materialInstances) inst.destroy();
    if (this._scroll) this._scroll.destroy();
    if (this._modal) this._modal.destroy();
    super.destroy();
  }
}
