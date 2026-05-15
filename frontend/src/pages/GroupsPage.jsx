import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useUI } from '../contexts/UIContext';
import GroupCard from '../components/GroupCard';
import Modal from '../components/Modal';
import LoadingSpinner from '../components/LoadingSpinner';
import useInfiniteScroll from '../hooks/useInfiniteScroll';
import { getGroupsApi, createGroupApi, joinGroupApi, leaveGroupApi, searchGroupsApi } from '../api/group.api';

export default function GroupsPage() {
  const navigate = useNavigate();
  const { addSuccessToast, addErrorToast } = useUI();
  const [groups, setGroups] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);

  const categories = ['', 'Tecnologia', 'Ciência', 'Artes', 'Esportes', 'Música', 'Acadêmico'];

  const loadGroups = useCallback(async (p) => {
    setIsLoading(true);
    try {
      const data = searchQuery
        ? await searchGroupsApi({ q: searchQuery, page: p, size: 20 })
        : await getGroupsApi({ page: p, size: 20 });
      const items = data.content || data || [];
      if (p === 0) setGroups(items);
      else setGroups(prev => [...prev, ...items]);
      setHasMore(data.last === false);
      setPage(p);
    } catch {
      setGroups([]);
    } finally {
      setIsLoading(false);
    }
  }, [searchQuery]);

  useEffect(() => { loadGroups(0); }, [loadGroups]);

  const loadMore = useCallback(async () => {
    if (!hasMore) return;
    return loadGroups(page + 1);
  }, [hasMore, page, loadGroups]);

  const { sentinelRef } = useInfiniteScroll(loadMore, { enabled: hasMore && !isLoading });

  const handleGroupAction = async (groupId) => {
    const group = groups.find(g => g.id === groupId);
    if (!group) return;
    try {
      if (group.isMember) {
        await leaveGroupApi(groupId);
        setGroups(prev => prev.map(g => g.id === groupId ? { ...g, isMember: false, memberCount: g.memberCount - 1 } : g));
      } else {
        await joinGroupApi(groupId);
        setGroups(prev => prev.map(g => g.id === groupId ? { ...g, isMember: true, memberCount: g.memberCount + 1 } : g));
      }
    } catch { addErrorToast('Erro ao entrar/sair do grupo'); }
  };

  const handleCreate = async ({ name, description, category }) => {
    if (!name?.trim()) return;
    try {
      const newGroup = await createGroupApi({ name, description, category });
      setGroups(prev => [newGroup, ...prev]);
      setShowCreateModal(false);
      addSuccessToast('Grupo criado!');
    } catch { addErrorToast('Erro ao criar grupo'); }
  };

  return (
    <div className="groups-page">
      <div className="page-header">
        <div className="flex items-center justify-between">
          <h2 className="page-title">Grupos</h2>
          <button className="btn btn-primary btn-sm" onClick={() => setShowCreateModal(true)}>+ Criar</button>
        </div>
        <div className="search-bar mt-sm">
          <span className="search-icon">🔍</span>
          <input type="search" placeholder="Buscar grupos..." value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)} />
        </div>
      </div>

      <div style={{ padding: 'var(--spacing-sm) var(--spacing-lg)', display: 'flex', gap: 8, flexWrap: 'wrap', borderBottom: '1px solid var(--border-primary)' }}>
        {categories.map(c => (
          <span key={c}
            className={`chip ${selectedCategory === c ? 'chip-active' : ''}`}
            onClick={() => { setSelectedCategory(c); setGroups([]); setPage(0); setHasMore(true); }}>
            {c || 'Todos'}
          </span>
        ))}
      </div>

      {isLoading
        ? <LoadingSpinner size="lg" />
        : groups.length === 0
          ? <div className="empty-state"><div className="empty-state-icon">👥</div><div className="empty-state-text">Nenhum grupo encontrado</div></div>
          : <div>{groups.map(g => (
              <div key={g.id} onClick={() => navigate(`/groups/${g.id}`)} style={{ cursor: 'pointer' }}>
                <GroupCard group={g} onAction={handleGroupAction} />
              </div>
            ))}
            {!hasMore && <div className="text-center text-muted py-md" style={{ padding: 16 }}>Você viu tudo!</div>}
            <div ref={sentinelRef} className="infinite-scroll-trigger" />
          </div>
      }

      {showCreateModal && (
        <CreateGroupModal
          onClose={() => setShowCreateModal(false)}
          onCreate={handleCreate}
        />
      )}
    </div>
  );
}

function CreateGroupModal({ onClose, onCreate }) {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState('');

  return (
    <Modal
      title="Criar Grupo"
      onClose={onClose}
      showClose
      footer={
        <>
          <button className="btn btn-secondary" onClick={onClose}>Cancelar</button>
          <button className="btn btn-primary" onClick={() => onCreate({ name, description, category })}>Criar</button>
        </>
      }
      content={
        <>
          <div className="form-group">
            <label>Nome do grupo</label>
            <input type="text" placeholder="Nome do grupo" value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Descrição</label>
            <textarea placeholder="Descrição do grupo" style={{ minHeight: 80 }} value={description}
              onChange={(e) => setDescription(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Categoria</label>
            <select value={category} onChange={(e) => setCategory(e.target.value)}>
              <option value="">Selecione</option>
              <option value="Tecnologia">Tecnologia</option>
              <option value="Ciência">Ciência</option>
              <option value="Artes">Artes</option>
              <option value="Esportes">Esportes</option>
              <option value="Música">Música</option>
              <option value="Acadêmico">Acadêmico</option>
            </select>
          </div>
        </>
      }
    />
  );
}
