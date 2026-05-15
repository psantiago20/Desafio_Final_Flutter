import Component from '../Component.js';

export default class MessagesPage extends Component {
    constructor() {
        super();
    }

    render() {
        // Load the messages.html template
        fetch('/frontend/pages/messages.html')
            .then(response => response.text())
            .then(html => {
                this.container.innerHTML = html;
                // After loading, add event listeners
                this.addEventListeners();
            })
            .catch(err => {
                console.error('Failed to load messages page:', err);
                this.container.innerHTML = '<p>Erro ao carregar a página de mensagens.</p>';
            });
    }

    addEventListeners() {
        // Find the "Nova mensagem" button by its text content
        const buttons = this.container.querySelectorAll('button');
        let newMessageBtn = null;
        buttons.forEach(btn => {
            if (btn.textContent.trim() === 'Nova mensagem') {
                newMessageBtn = btn;
            }
        });
        if (newMessageBtn) {
            newMessageBtn.addEventListener('click', () => {
                // Abrir modal para nova conversa ou redirecionar para busca de usuário
                alert('Funcionalidade de nova mensagem em desenvolvimento');
            });
        }

        // Add click listener to each conversation item to navigate to conversation
        const conversationItems = this.container.querySelectorAll('.conversation-item');
        conversationItems.forEach(item => {
            item.addEventListener('click', () => {
                // For now, navigate to a fixed conversation ID for testing
                window.location.hash = '#/messages/1';
            });
        });
    }
}