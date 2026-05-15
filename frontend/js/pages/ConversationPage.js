import Component from '../Component.js';

export default class ConversationPage extends Component {
    constructor() {
        super();
    }

    render() {
        // Load the conversation.html template
        fetch('/frontend/pages/conversation.html')
            .then(response => response.text())
            .then(html => {
                this.container.innerHTML = html;
                // After loading, add event listeners
                this.addEventListeners();
                // We would normally load conversation data here based on the route param :id
                // For now, we just show static content
            })
            .catch(err => {
                console.error('Failed to load conversation page:', err);
                this.container.innerHTML = '<p>Erro ao carregar a página de conversa.</p>';
            });
    }

    addEventListeners() {
        const backButton = this.container.querySelector('.back-button');
        if (backButton) {
            backButton.addEventListener('click', () => {
                window.location.hash = '#/messages';
            });
        }

        const sendButton = this.container.querySelector('#send-button');
        const messageInput = this.container.querySelector('#message-input');
        if (sendButton && messageInput) {
            sendButton.addEventListener('click', () => {
                const message = messageInput.value.trim();
                if (message) {
                    // In a real app, we would send the message to the backend
                    // For now, just simulate by adding a sent message bubble
                    this.addSentMessage(message);
                    messageInput.value = '';
                }
            });
            messageInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    sendButton.click();
                }
            });
        }
    }

    addSentMessage(content) {
        const messagesContainer = this.container.querySelector('.messages-container');
        if (!messagesContainer) return;

        const messageDiv = document.createElement('div');
        messageDiv.className = 'message-bubble sent';
        messageDiv.innerHTML = `
            <div class="content">${this.escapeHtml(content)}</div>
            <div class="meta">agora</div>
        `;
        messagesContainer.appendChild(messageDiv);
        // Scroll to bottom
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    escapeHtml(text) {
        const map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return text.replace(/[&<>"']/g, m => map[m]);
    }
}