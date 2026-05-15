import Component from './Component.js';
import { escapeHtml, truncateText } from '../utils/helpers.js';

export default class MaterialCard extends Component {
  template() {
    const item = this.props.item || {};
    const type = (item.type || 'document').toLowerCase();
    const typeIcons = { pdf: '📄', video: '🎬', link: '🔗', document: '📝' };
    const typeIcon = typeIcons[type] || '📝';

    return `
      <div class="material-card" data-material-id="${item.id || ''}">
        <div class="material-card-type">${typeIcon} ${type}</div>
        <div class="material-card-title">${escapeHtml(item.title || '')}</div>
        <div class="material-card-desc">${escapeHtml(truncateText(item.description || '', 120))}</div>
        ${item.tags && item.tags.length ? `
          <div class="flex flex-wrap gap-sm" style="margin-top:4px">
            ${item.tags.map(t => `<span class="chip chip-sm">${escapeHtml(t)}</span>`).join('')}
          </div>
        ` : ''}
        <div class="material-card-footer">
          <span>📥 ${item.downloadCount || 0} downloads</span>
          ${item.size ? `<span>${item.size}</span>` : ''}
        </div>
      </div>
    `;
  }
}
