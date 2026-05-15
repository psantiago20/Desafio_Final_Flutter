import Component from './Component.js';

export default class LoadingSpinner extends Component {
  template() {
    const { size = 'md', overlay = false, text = '' } = this.props;
    const sizeClass = size === 'lg' ? 'spinner-lg' : '';
    return `
      <div class="loading-spinner ${overlay ? 'loading-overlay' : 'loading-inline'}">
        <div class="spinner ${sizeClass}"></div>
        ${text ? `<span class="loading-text text-muted">${text}</span>` : ''}
      </div>
    `;
  }
}
