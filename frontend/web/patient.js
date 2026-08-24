// ─── Tailwind Config ─────────────────────────────────────────────────────────
tailwind.config = {
    darkMode: "class",
    theme: {
        extend: {
            colors: {
                "primary": "var(--color-primary)",
                "primary-fixed": "var(--color-primary-fixed)",
                "on-primary": "var(--color-on-primary)",
                "on-primary-fixed": "var(--color-on-primary-fixed)",
                "surface": "var(--color-surface)",
                "on-surface": "var(--color-on-surface)",
                "surface-variant": "var(--color-surface-variant)",
                "on-surface-variant": "var(--color-on-surface-variant)",
                "background": "var(--color-background)",
                "on-background": "var(--color-on-background)",
                "outline": "var(--color-outline)",
                "outline-variant": "var(--color-outline-variant)",
                "surface-container-lowest": "var(--color-surface-container-lowest)",
                "surface-container-low": "var(--color-surface-container-low)",
                "surface-container": "var(--color-surface-container)",
                "surface-container-highest": "var(--color-surface-container-highest)",
                "error": "var(--color-error)",
                "on-error": "var(--color-on-error)",
                // Compatibilidade retroativa para classes que não foram mapeadas
                "secondary": "#4E8EA2",
                "secondary-container": "#6EA2B3",
                "tertiary": "#7BBDE8",
                "error-container": "#FEE2E2",
            },
            borderRadius: {
                "DEFAULT": "0.25rem",
                "lg": "0.5rem",
                "xl": "0.75rem",
                "xxl": "1.5rem",
                "full": "9999px"
            },
            fontFamily: {
                "headline": ["Manrope"],
                "display": ["Manrope"],
                "body": ["Inter"],
                "label": ["Inter"]
            }
        }
    }
};

// ─── Theme Toggle Logic ────────────────────────────────────────────────────────
function toggleTheme() {
    const htmlEl = document.documentElement;
    const isDark = htmlEl.classList.toggle('dark');
    const themeIcon = document.getElementById('theme-icon');
    
    if (isDark) {
        htmlEl.classList.remove('light');
        localStorage.setItem('theme', 'dark');
        if(themeIcon) themeIcon.textContent = 'light_mode';
    } else {
        htmlEl.classList.add('light');
        localStorage.setItem('theme', 'light');
        if(themeIcon) themeIcon.textContent = 'dark_mode';
    }
}

function initTheme() {
    const savedTheme = localStorage.getItem('theme');
    const htmlEl = document.documentElement;
    
    if (savedTheme === 'dark' || (!savedTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
        htmlEl.classList.add('dark');
        htmlEl.classList.remove('light');
    } else {
        htmlEl.classList.add('light');
        htmlEl.classList.remove('dark');
    }
}

// Inicializar tema imediatamente
initTheme();

// ─── Navigation ───────────────────────────────────────────────────────────────
const TABS = ['chat', 'calendar', 'dashboard'];

function switchTab(tab) {
    // Update panels
    TABS.forEach(t => {
        const panel = document.getElementById(`panel-${t}`);
        if (panel) {
            panel.classList.toggle('active', t === tab);
        }
    });

    // Update bottom nav buttons
    document.querySelectorAll('[data-tab]').forEach(btn => {
        const isActive = btn.dataset.tab === tab;
        btn.classList.toggle('nav-tab-active', isActive);
        // Reset/set text color
        if (isActive) {
            btn.querySelectorAll('span').forEach(s => s.style.color = '');
        } else {
            btn.querySelectorAll('span').forEach(s => s.style.color = '');
        }
    });

    // If navigating to dashboard, redirect to the app's internal dashboard route
    if (tab === 'dashboard') {
        window.location.href = 'index.html#/dashboard';
        return;
    }
}

// ─── Chat Logic ───────────────────────────────────────────────────────────────
const API_BASE = 'http://127.0.0.1:8000';

async function sendChatMessage() {
    const input = document.getElementById('chat-input');
    const sendBtn = document.getElementById('send-btn');
    const text = input.value.trim();
    if (!text) return;

    input.value = '';
    sendBtn.disabled = true;

    appendMessage(text, 'user');
    const loadingId = appendLoadingBubble();

    try {
        const response = await fetch(`${API_BASE}/api/webhooks/chat-direct`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                to: '5511988888888', 
                message: text,
                wa_to: '5511912345678'
            })
        });

        removeLoadingBubble(loadingId);

        if (response.ok) {
            const data = await response.json();
            appendMessage(data.response || 'Sem resposta.', 'ai');
        } else {
            appendMessage('Não consegui obter resposta. Tente novamente.', 'ai');
        }
    } catch (err) {
        removeLoadingBubble(loadingId);
        appendMessage('Erro de conexão com o servidor.', 'ai');
    } finally {
        sendBtn.disabled = false;
        input.focus();
    }
}

function appendMessage(text, role) {
    const container = document.getElementById('chat-messages');
    const div = document.createElement('div');
    div.className = 'timeline-item';

    const now = new Date();
    const timeStr = now.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
    const dayStr = 'HOJE'; // Consistent with dashboard style

    let icon = 'psychology';
    let title = 'IA · Sua Consulta';
    let iconBg = '#dae2ff';
    let iconColor = '#003d9b';
    let cardClass = '';
    let contentClass = 'timeline-content';
    let badges = [];

    if (role === 'user') {
        icon = 'person';
        title = 'Você';
        iconBg = '#f1f5f9';
        iconColor = '#475569';
        cardClass = 'user-card';
        contentClass += ' is-message';
    } else if (role === 'doctor') {
        icon = 'medical_services';
        title = 'Dr. Thorne';
        iconBg = '#eceef0';
        iconColor = '#475569';
        badges = ['RETORNO SOLICITADO'];
    } else {
        // AI
        icon = 'auto_awesome';
        title = 'Assistente IA / Médico';
        iconBg = '#dae2ff';
        iconColor = '#003d9b';
        contentClass += ' is-message';
    }

    div.innerHTML = `
        <div class="timeline-icon-container">
            <div class="timeline-icon" style="background-color: ${iconBg}; color: ${iconColor};">
                <span class="material-symbols-outlined !text-[16px]">${icon}</span>
            </div>
        </div>
        <div class="timeline-card ${cardClass}">
            <div class="timeline-header">
                <span class="timeline-title">${title}</span>
                <span class="timeline-time">${dayStr}, ${timeStr}</span>
            </div>
            <div class="${contentClass}">
                ${text.replace(/\n/g, '<br>')}
            </div>
            ${badges.length > 0 ? `
                <div class="timeline-badges">
                    ${badges.map(b => `<span class="timeline-badge badge-success">${b}</span>`).join('')}
                </div>
            ` : ''}
        </div>
    `;

    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
}

function appendLoadingBubble() {
    const container = document.getElementById('chat-messages');
    const id = `loading-${Date.now()}`;
    const div = document.createElement('div');
    div.id = id;
    div.className = 'timeline-item';
    div.innerHTML = `
        <div class="timeline-icon-container">
            <div class="timeline-icon" style="background-color: #dae2ff; color: #003d9b;">
                <span class="material-symbols-outlined !text-[16px] animate-spin">sync</span>
            </div>
        </div>
        <div class="timeline-card">
            <div class="timeline-header">
                <span class="timeline-title">IA · Processando...</span>
            </div>
            <div class="timeline-content">
                <span class="text-xs text-outline italic">Analisando sua solicitação...</span>
            </div>
        </div>
    `;
    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
    return id;
}

function removeLoadingBubble(id) {
    const el = document.getElementById(id);
    if (el) el.remove();
}

// ─── Calendar Logic ───────────────────────────────────────────────────────────
const APPOINTMENTS = {
    28: 'Consulta - 14:30 com Dr. Thorne',
    5: 'Retorno - 10:00 com Dr. Thorne',
    12: 'Exame de Sangue - Laboratório'
};

let currentDate = new Date();

function renderCalendar() {
    const monthNames = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho',
                        'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();

    document.getElementById('calendar-month-year').textContent = `${monthNames[month]} ${year}`;

    const firstDay = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const today = new Date();

    const grid = document.getElementById('calendar-grid');
    grid.innerHTML = '';

    // Day headers
    ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'].forEach(day => {
        const el = document.createElement('div');
        el.className = 'text-center text-[10px] font-bold text-outline uppercase tracking-widest py-1';
        el.textContent = day;
        grid.appendChild(el);
    });

    // Empty cells
    for (let i = 0; i < firstDay; i++) {
        grid.appendChild(document.createElement('div'));
    }

    // Day cells
    for (let d = 1; d <= daysInMonth; d++) {
        const el = document.createElement('div');
        el.className = 'calendar-day text-center text-sm py-1.5 relative';
        el.textContent = d;

        const isToday = d === today.getDate() && month === today.getMonth() && year === today.getFullYear();
        if (isToday) el.classList.add('today');
        if (APPOINTMENTS[d]) el.classList.add('has-appointment');

        el.addEventListener('click', () => showAppointmentDetail(d));
        grid.appendChild(el);
    }
}

function showAppointmentDetail(day) {
    const detail = document.getElementById('appointment-detail');
    if (APPOINTMENTS[day]) {
        detail.textContent = `📅 Dia ${day}: ${APPOINTMENTS[day]}`;
        detail.classList.remove('hidden');
    } else {
        detail.classList.add('hidden');
    }
}

function prevMonth() {
    currentDate.setMonth(currentDate.getMonth() - 1);
    renderCalendar();
}

function nextMonth() {
    currentDate.setMonth(currentDate.getMonth() + 1);
    renderCalendar();
}

// ─── File Upload ──────────────────────────────────────────────────────────────
function setupUploadZone() {
    const zone = document.getElementById('upload-zone');
    const fileInput = document.getElementById('file-input');
    const fileList = document.getElementById('file-list');

    if (!zone) return;

    zone.addEventListener('click', () => fileInput.click());

    zone.addEventListener('dragover', (e) => {
        e.preventDefault();
        zone.classList.add('drag-over');
    });

    zone.addEventListener('dragleave', () => zone.classList.remove('drag-over'));

    zone.addEventListener('drop', (e) => {
        e.preventDefault();
        zone.classList.remove('drag-over');
        handleFiles(e.dataTransfer.files);
    });

    fileInput.addEventListener('change', () => handleFiles(fileInput.files));

    function handleFiles(files) {
        Array.from(files).forEach(file => {
            const item = document.createElement('div');
            item.className = 'flex items-center gap-3 p-3 bg-surface-container-low rounded-xl';
            const icon = file.type.includes('pdf') ? 'picture_as_pdf' : 'description';
            const iconColor = file.type.includes('pdf') ? 'text-error' : 'text-primary';
            item.innerHTML = `
                <span class="material-symbols-outlined ${iconColor}">${icon}</span>
                <div class="flex-1 min-w-0">
                    <p class="text-sm font-bold truncate">${file.name}</p>
                    <p class="text-[10px] text-outline">${(file.size / 1024).toFixed(1)} KB</p>
                </div>
                <span class="text-[10px] font-bold text-secondary bg-secondary-container px-2 py-1 rounded-full">Enviado</span>
            `;
            fileList.prepend(item);
        });
        fileInput.value = '';
    }
}

// ─── Init ─────────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    // Definir ícone inicial do tema
    const themeIcon = document.getElementById('theme-icon');
    if (themeIcon) {
        themeIcon.textContent = document.documentElement.classList.contains('dark') ? 'light_mode' : 'dark_mode';
    }

    // Default tab
    switchTab('chat');

    // Calendar init
    renderCalendar();

    // Upload zone
    setupUploadZone();

    // Chat input enter key
    const input = document.getElementById('chat-input');
    if (input) {
        input.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                sendChatMessage();
            }
        });
    }

    // Initial AI greeting
    setTimeout(() => {
        appendMessage('Oi! Tudo bem? ✨ Sou a Isis, sua assistente virtual. Estou aqui para cuidar de você e facilitar seu atendimento. Como posso te ajudar hoje? 😊', 'ai');
    }, 400);
});
