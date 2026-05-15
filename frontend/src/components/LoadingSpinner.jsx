export default function LoadingSpinner({ size = 'md', overlay = false, text = '' }) {
  const sizeClass = size === 'lg' ? 'spinner-lg' : '';
  return (
    <div className={`loading-spinner ${overlay ? 'loading-overlay' : 'loading-inline'}`}>
      <div className={`spinner ${sizeClass}`}></div>
      {text && <span className="loading-text text-muted">{text}</span>}
    </div>
  );
}
