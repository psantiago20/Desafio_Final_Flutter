import { useState, useEffect, useCallback } from 'react';
import Modal from '../components/Modal';
import MaterialCard from '../components/MaterialCard';
import LoadingSpinner from '../components/LoadingSpinner';
import useInfiniteScroll from '../hooks/useInfiniteScroll';
import { getLibraryApi, searchLibraryApi, createLibraryItemApi } from '../api/library.api';
import { useUI } from '../contexts/UIContext';

export default function LibraryPage() {
  const { addSuccessToast, addErrorToast } = useUI();
  const [materials, setMaterials] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [showUploadModal, setShowUploadModal] = useState(false);

  const types = ['', 'PDF', 'VIDEO', 'LINK', 'DOCUMENT'];
  const typeLabels = { '': 'Todos', PDF: '📄 PDF', VIDEO: '🎬 Vídeo', LINK: '🔗 Link', DOCUMENT: '📝 Documento' };

  const loadMaterials = useCallback(async (p) => {
    setIsLoading(true);
    try {
      const data = searchQuery
        ? await searchLibraryApi({ q: searchQuery, type: typeFilter, page: p, size: 20 })
        : await getLibraryApi({ type: typeFilter, page: p, size: 20 });
      const items = data.content || data || [];
      if (p === 0) setMaterials(items);
      else setMaterials(prev => [...prev, ...items]);
      setHasMore(data.last === false);
      setPage(p);
    } catch { setMaterials([]); }
    finally { setIsLoading(false); }
  }, [searchQuery, typeFilter]);

  useEffect(() => { loadMaterials(0); }, [loadMaterials]);

  const loadMore = useCallback(async () => {
    if (!hasMore) return;
    return loadMaterials(page + 1);
  }, [hasMore, page, loadMaterials]);

  const { sentinelRef } = useInfiniteScroll(loadMore, { enabled: hasMore && !isLoading });

  const handleUpload = async ({ title, description, type, url, tags }) => {
    if (!title?.trim()) return;
    try {
      const item = await createLibraryItemApi({
        title, description, type, url,
        tags: tags ? tags.split(',').map(t => t.trim()).filter(Boolean) : [],
      });
      setMaterials(prev => [item, ...prev]);
      setShowUploadModal(false);
      addSuccessToast('Material adicionado!');
    } catch { addErrorToast('Erro ao adicionar material'); }
  };

  return (
    <div className="library-page">
      <div className="page-header">
        <div className="flex items-center justify-between">
          <h2 className="page-title">Biblioteca</h2>
          <button className="btn btn-primary btn-sm" onClick={() => setShowUploadModal(true)}>+ Upload</button>
        </div>
        <div className="search-bar mt-sm">
          <span className="search-icon">🔍</span>
          <input type="search" placeholder="Buscar materiais..." value={searchQuery}
            onChange={(e) => { setSearchQuery(e.target.value); setPage(0); }} />
        </div>
      </div>

      <div style={{ padding: 'var(--spacing-sm) var(--spacing-lg)', display: 'flex', gap: 8, flexWrap: 'wrap', borderBottom: '1px solid var(--border-primary)' }}>
        {types.map(t => (
          <span key={t}
            className={`chip ${typeFilter === t ? 'chip-active' : ''}`}
            onClick={() => { setTypeFilter(t); setPage(0); }}>
            {typeLabels[t] || t}
          </span>
        ))}
      </div>

      {isLoading
        ? <LoadingSpinner size="lg" />
        : materials.length === 0
          ? <div className="empty-state"><div className="empty-state-icon">📚</div><div className="empty-state-text">Nenhum material encontrado</div></div>
          : <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(240px,1fr))', gap: 8, padding: 'var(--spacing-md)' }}>
              {materials.map(m => <MaterialCard key={m.id} item={m} />)}
            </div>
      }

      {!hasMore && materials.length > 0 && (
        <div className="text-center text-muted py-md" style={{ padding: 16 }}>Você viu tudo!</div>
      )}
      <div ref={sentinelRef} className="infinite-scroll-trigger" />

      {showUploadModal && (
        <UploadModal
          onClose={() => setShowUploadModal(false)}
          onUpload={handleUpload}
        />
      )}
    </div>
  );
}

function UploadModal({ onClose, onUpload }) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [type, setType] = useState('PDF');
  const [url, setUrl] = useState('');
  const [tags, setTags] = useState('');

  return (
    <Modal
      title="Adicionar Material"
      onClose={onClose}
      showClose
      footer={
        <>
          <button className="btn btn-secondary" onClick={onClose}>Cancelar</button>
          <button className="btn btn-primary" onClick={() => onUpload({ title, description, type, url, tags })}>Adicionar</button>
        </>
      }
      content={
        <>
          <div className="form-group">
            <label>Título</label>
            <input type="text" placeholder="Título do material" value={title} onChange={(e) => setTitle(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Descrição</label>
            <textarea placeholder="Descrição" style={{ minHeight: 60 }} value={description} onChange={(e) => setDescription(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Tipo</label>
            <select value={type} onChange={(e) => setType(e.target.value)}>
              <option value="PDF">PDF</option>
              <option value="VIDEO">Vídeo</option>
              <option value="LINK">Link</option>
              <option value="DOCUMENT">Documento</option>
            </select>
          </div>
          <div className="form-group">
            <label>URL</label>
            <input type="url" placeholder="https://..." value={url} onChange={(e) => setUrl(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Tags (separadas por vírgula)</label>
            <input type="text" placeholder="tag1, tag2" value={tags} onChange={(e) => setTags(e.target.value)} />
          </div>
        </>
      }
    />
  );
}
