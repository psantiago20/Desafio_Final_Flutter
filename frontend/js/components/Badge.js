import Component from './Component.js';
import { escapeHtml } from '../utils/helpers.js';

export default class BadgeComponent extends Component {
  template() {
    const badge = this.props.badge || {};
    const unlocked = badge.unlocked ?? badge.achieved ?? false;

    return `
      <div class="badge-display ${unlocked ? '' : 'badge-locked'}" style="${unlocked ? '' : 'opacity:0.4'}">
        <div class="badge-icon">${unlocked ? (badge.icon || '🏅') : '🔒'}</div>
        <div class="badge-info">
          <div class="badge-name">${escapeHtml(badge.name || '')}</div>
          <div class="badge-desc">${escapeHtml(badge.description || '')}</div>
        </div>
        ${unlocked && badge.unlockedAt ? `
          <span class="text-muted" style="font-size:11px;flex-shrink:0">${new Date(badge.unlockedAt).toLocaleDateString('pt-BR')}</span>
        ` : ''}
      </div>
    `;
  }
}
