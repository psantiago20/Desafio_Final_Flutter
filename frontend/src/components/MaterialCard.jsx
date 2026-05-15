import { escapeHtml } from '../utils/helpers';

export default function MaterialCard({ item }) {
  if (!item) return null;
  const type = (item.type || 'document').toLowerCase();
  const typeIcons = { pdf: '📄', video: '🎬', link: '🔗', document: '📝' };
  const typeIcon = typeIcons[type] || '📝';

  function truncateText(text, max = 120) {
    if (!text) return '';
    if (text.length <= max) return text;
    return text.slice(0, max).trimEnd() + '…';
  }

  return (
    <div className="material-card">
      <div className="material-card-type">{typeIcon} {type}</div>
      <div className="material-card-title">{escapeHtml(item.title || '')}</div>
      <div className="material-card-desc">{escapeHtml(truncateText(item.description || ''))}</div>
      {item.tags?.length > 0 && (
        <div className="flex flex-wrap gap-sm" style={{ marginTop: 4 }}>
          {item.tags.map(t => <span key={t} className="chip chip-sm">{escapeHtml(t)}</span>)}
        </div>
      )}
      <div className="material-card-footer">
        <span>📥 {item.downloadCount || 0} downloads</span>
        {item.size && <span>{item.size}</span>}
      </div>
    </div>
  );
}
