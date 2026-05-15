import { useEffect } from 'react';

export default function Modal({ title, content, footer, showClose = true, wide, onClose }) {
  useEffect(() => {
    const handler = (e) => { if (e.key === 'Escape') onClose?.(); };
    document.addEventListener('keydown', handler);
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', handler);
      document.body.style.overflow = '';
    };
  }, [onClose]);

  return (
    <div className="modal-overlay" data-modal-overlay onClick={(e) => {
      if (e.target.dataset.modalOverlay !== undefined) onClose?.();
    }}>
      <div className="modal-content" style={wide ? { maxWidth: 720 } : {}}>
        <div className="modal-header">
          <div className="modal-title">{title}</div>
          {showClose && <button className="modal-close" onClick={() => onClose?.()}>✕</button>}
        </div>
        <div className="modal-body">{content}</div>
        {footer && (
          <div className="modal-footer"
            style={{ padding: 'var(--spacing-md) var(--spacing-lg)', borderTop: '1px solid var(--border-primary)', display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}

export function ModalTrigger({ children }) {
  return children;
}
