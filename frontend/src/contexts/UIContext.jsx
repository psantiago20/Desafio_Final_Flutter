import { createContext, useContext, useState, useCallback } from 'react';
import { TOAST_DURATION, TOAST_ERROR_DURATION } from '../constants/config';

const UIContext = createContext(null);

export function UIProvider({ children }) {
  const [toasts, setToasts] = useState([]);

  const addToast = useCallback((toast) => {
    const id = Date.now();
    setToasts(prev => [...prev, { id, ...toast }]);
    const duration = toast.type === 'error' ? TOAST_ERROR_DURATION : TOAST_DURATION;
    setTimeout(() => removeToast(id), duration);
    return id;
  }, []);

  const removeToast = useCallback((id) => {
    setToasts(prev => prev.filter(t => t.id !== id));
  }, []);

  const addSuccessToast = useCallback((message) => {
    return addToast({ type: 'success', message });
  }, [addToast]);

  const addErrorToast = useCallback((message) => {
    return addToast({ type: 'error', message });
  }, [addToast]);

  return (
    <UIContext.Provider value={{
      toasts, addToast, removeToast, addSuccessToast, addErrorToast,
    }}>
      {children}
      <div id="toast-container" className="toast-container">
        {toasts.map(t => (
          <div key={t.id} className={`toast ${t.type ? `toast-${t.type}` : ''}`}>
            <span>{t.type === 'success' ? '✅' : t.type === 'error' ? '❌' : 'ℹ️'}</span>
            <span>{t.message}</span>
            <span className="toast-close" onClick={() => removeToast(t.id)}>✕</span>
          </div>
        ))}
      </div>
    </UIContext.Provider>
  );
}

export function useUI() {
  const ctx = useContext(UIContext);
  if (!ctx) throw new Error('useUI must be used within UIProvider');
  return ctx;
}
