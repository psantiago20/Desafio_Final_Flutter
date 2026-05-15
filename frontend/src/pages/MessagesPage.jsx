import { Link } from 'react-router-dom';

const conversations = [
  { id: 1, name: 'João Silva', username: 'joaosilva', lastMessage: 'Vamos marcar a reunião?', time: '5min', unread: 2 },
  { id: 2, name: 'Maria Santos', username: 'mariasantos', lastMessage: 'Obrigado pela ajuda!', time: '1h', unread: 0 },
  { id: 3, name: 'Carlos Pereira', username: 'carlospereira', lastMessage: 'Recebi o material', time: '2h', unread: 0 },
];

export default function MessagesPage() {
  return (
    <div className="messages-page">
      <div className="page-header">
        <div className="flex items-center justify-between">
          <h2 className="page-title">Mensagens</h2>
          <button className="btn btn-primary btn-sm"
            onClick={() => alert('Funcionalidade de nova mensagem em desenvolvimento')}>
            Nova mensagem
          </button>
        </div>
      </div>

      <div>
        {conversations.map(c => (
          <Link key={c.id} to={`/messages/${c.id}`}
            className="conversation-item"
            style={{
              display: 'flex', alignItems: 'center', gap: 12,
              padding: '12px var(--spacing-lg)', borderBottom: '1px solid var(--border-secondary)',
              textDecoration: 'none', color: 'inherit',
            }}>
            <div className="avatar avatar-sm avatar-placeholder" style={{ fontSize: 12 }}>
              {c.name.split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase()}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <strong>{c.name}</strong>
                <span className="text-muted" style={{ fontSize: 12 }}>{c.time}</span>
              </div>
              <div style={{ display: 'flex', gap: 4 }}>
                <span className="text-muted" style={{ fontSize: 13, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {c.lastMessage}
                </span>
                {c.unread > 0 && <span className="badge">{c.unread}</span>}
              </div>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
