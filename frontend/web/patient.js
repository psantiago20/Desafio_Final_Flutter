// ─── Tailwind Config ─────────────────────────────────────────────────────────
tailwind.config = {
    darkMode: "class",
    theme: {
        extend: {
            colors: {
                "outline": "#737685",
                "surface-container-high": "#e6e8ea",
                "surface-container-highest": "#e0e3e5",
                "on-tertiary-fixed": "#380d00",
                "on-primary-fixed": "#001848",
                "surface-variant": "#e0e3e5",
                "on-error-container": "#93000a",
                "secondary": "#006c4d",
                "secondary-fixed": "#86f8c8",
                "on-tertiary-container": "#ffc6b2",
                "on-secondary": "#ffffff",
                "background": "#f7f9fb",
                "tertiary": "#7b2600",
                "surface-container-lowest": "#ffffff",
                "surface-container": "#eceef0",
                "error-container": "#ffdad6",
                "on-primary-container": "#c4d2ff",
                "error": "#ba1a1a",
                "secondary-fixed-dim": "#69dbad",
                "on-tertiary-fixed-variant": "#812800",
                "tertiary-fixed-dim": "#ffb59b",
                "surface-container-low": "#f2f4f6",
                "secondary-container": "#86f8c8",
                "on-surface": "#191c1e",
                "surface-bright": "#f7f9fb",
                "on-primary-fixed-variant": "#0040a2",
                "on-background": "#191c1e",
                "inverse-primary": "#b2c5ff",
                "on-error": "#ffffff",
                "inverse-surface": "#2d3133",
                "primary-fixed-dim": "#b2c5ff",
                "on-secondary-container": "#007352",
                "on-surface-variant": "#434654",
                "primary-container": "#0052cc",
                "on-tertiary": "#ffffff",
                "primary-fixed": "#dae2ff",
                "surface-tint": "#0c56d0",
                "inverse-on-surface": "#eff1f3",
                "tertiary-container": "#a33500",
                "tertiary-fixed": "#ffdbcf",
                "primary": "#003d9b",
                "on-primary": "#ffffff",
                "on-secondary-fixed": "#002115",
                "surface": "#f7f9fb",
                "on-secondary-fixed-variant": "#005139",
                "outline-variant": "#c3c6d6",
                "surface-dim": "#d8dadc"
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

    // If navigating to dashboard, redirect
    if (tab === 'dashboard') {
        window.location.href = 'index.html';
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
            body: JSON.stringify({ to: 'paciente_web', message: text })
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
    div.className = `chat-bubble-${role}`;

    if (role === 'ai') {
        const badge = document.createElement('p');
        badge.className = 'text-[10px] font-bold uppercase tracking-widest text-outline mb-1';
        badge.textContent = '✦ IA · Sua Consulta';
        div.appendChild(badge);
    } else if (role === 'doctor') {
        const badge = document.createElement('p');
        badge.className = 'text-[10px] font-bold uppercase tracking-widest text-outline mb-1';
        badge.textContent = '👨‍⚕️ Dr. Thorne';
        div.appendChild(badge);
    }

    const p = document.createElement('p');
    p.className = 'text-sm leading-relaxed';
    p.textContent = text;
    div.appendChild(p);

    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
}

function appendLoadingBubble() {
    const container = document.getElementById('chat-messages');
    const id = `loading-${Date.now()}`;
    const div = document.createElement('div');
    div.id = id;
    div.className = 'chat-bubble-ai flex items-center gap-2';
    div.innerHTML = `
        <div class="spinner"></div>
        <span class="text-sm text-outline">Processando...</span>
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
        appendMessage('Olá! Sou a IA do Sua Consulta. Como posso te ajudar hoje?', 'ai');
    }, 400);
});
