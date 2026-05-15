import { useState, useRef, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';

export default function ConversationPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [messages, setMessages] = useState([
    { id: 1, text: 'Olá! Tudo bem?', sent: false, time: '10:30' },
    { id: 2, text: 'Tudo sim! E você?', sent: true, time: '10:31' },
  ]);
  const [input, setInput] = useState('');
  const messagesEndRef = useRef(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = () => {
    if (!input.trim()) return;
    setMessages(prev => [...prev, {
      id: Date.now(), text: input.trim(), sent: true, time: 'agora',
    }]);
    setInput('');
  };

  return (
    <div className="conversation-page" style={{ display: 'flex', flexDirection: 'column', height: 'calc(100vh - var(--nav-height) - var(--bottom-nav-height))' }}>
      <div className="page-header" style={{ flexShrink: 0 }}>
        <div className="flex items-center gap-md">
          <button className="nav-icon-btn" onClick={() => navigate('/messages')}>←</button>
          <h2 className="page-title">Conversa</h2>
        </div>
      </div>

      <div className="messages-container" style={{
        flex: 1, overflowY: 'auto', padding: 'var(--spacing-md)',
        display: 'flex', flexDirection: 'column', gap: 8,
      }}>
        {messages.map(m => (
          <div key={m.id} className={`message-bubble ${m.sent ? 'sent' : 'received'}`}
            style={{
              alignSelf: m.sent ? 'flex-end' : 'flex-start',
              maxWidth: '70%', padding: '8px 12px', borderRadius: 12,
              background: m.sent ? 'var(--accent-primary)' : 'var(--bg-tertiary)',
              color: m.sent ? '#fff' : 'var(--text-primary)',
            }}>
            <div className="content">{m.text}</div>
            <div className="meta" style={{ fontSize: 11, opacity: 0.7, marginTop: 2 }}>{m.time}</div>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      <div style={{
        display: 'flex', gap: 8, padding: 'var(--spacing-sm) var(--spacing-md)',
        borderTop: '1px solid var(--border-primary)',
      }}>
        <input
          id="message-input"
          type="text"
          placeholder="Digite sua mensagem..."
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyPress={(e) => { if (e.key === 'Enter') handleSend(); }}
          style={{ flex: 1, border: 'none', background: 'var(--bg-input)', borderRadius: 'var(--radius-md)', padding: '10px 14px', color: 'var(--text-primary)' }}
        />
        <button id="send-button" className="btn btn-primary btn-sm" onClick={handleSend}>Enviar</button>
      </div>
    </div>
  );
}
