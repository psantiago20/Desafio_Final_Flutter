# Frontend Vite + React — Estrutura final

```
frontend/
├── index.html                    ← Entry point Vite
├── package.json                  ← React 18, react-router-dom v6, Vite 5
├── vite.config.js                ← Proxy /api → localhost:8080
├── nginx.conf                    ← SPA fallback + proxy API
├── Dockerfile                    ← Multi-stage (Node build → nginx)
├── src/
│   ├── main.jsx                  ← Root com providers
│   ├── App.jsx                   ← React Router v6 (18 rotas)
│   ├── api/
│   │   ├── client.js             ← Fetch wrapper com refresh token
│   │   ├── auth.api.js
│   │   ├── user.api.js
│   │   ├── post.api.js
│   │   ├── group.api.js
│   │   ├── library.api.js
│   │   ├── mentorship.api.js
│   │   ├── gamification.api.js
│   │   └── notification.api.js
│   ├── contexts/
│   │   ├── AuthContext.jsx        ← Auth global com persistência
│   │   ├── UIContext.jsx          ← Toasts
│   │   └── ThemeContext.jsx       ← Dark/light theme
│   ├── components/               ← 12 componentes React
│   │   ├── Navbar.jsx, Sidebar.jsx, RightSidebar.jsx, BottomNav.jsx
│   │   ├── PostCard.jsx, PostComposer.jsx
│   │   ├── CommentItem.jsx, UserCard.jsx
│   │   ├── GroupCard.jsx, MaterialCard.jsx, NotificationItem.jsx
│   │   ├── Modal.jsx, LoadingSpinner.jsx, ThemeToggle.jsx
│   ├── pages/                    ← 16 páginas React
│   │   ├── AuthPage.jsx          ← Login/register (completo)
│   │   ├── FeedPage.jsx          ← Timeline + criar post + like/repost (completo)
│   │   ├── ExplorePage.jsx       ← Trending + scroll infinito (completo)
│   │   ├── ProfilePage.jsx       ← Perfil + tabs posts/likes (completo)
│   │   ├── ProfileEditPage.jsx   ← Editar perfil + upload avatar/banner (completo)
│   │   ├── PostDetailPage.jsx    ← Post + comentários (completo)
│   │   ├── GroupsPage.jsx        ← Lista + criar + filtro (completo)
│   │   ├── GroupDetailPage.jsx   ← Grupo + composer (completo)
│   │   ├── LibraryPage.jsx       ← Grid + upload modal (completo)
│   │   ├── MentorshipPage.jsx    ← Minhas/disponíveis + solicitar (completo)
│   │   ├── MentorshipSessionPage.jsx ← Sessões + agendar + feedback
│   │   ├── NotificationsPage.jsx ← Filtro + marcar lidas
│   │   ├── MessagesPage.jsx      ← Lista conversas
│   │   ├── ConversationPage.jsx  ← Chat UI
│   │   ├── SettingsPage.jsx      ← Tema, notificações, conta
│   │   └── AdminPage.jsx         ← Métricas, leaderboard, usuários
│   ├── hooks/useInfiniteScroll.js
│   ├── constants/api.js, config.js
│   └── utils/format.js, validation.js, helpers.js
├── css/                          ← Inalterado
└── public/                       ← Manifest, icons
```

## Para rodar

```
# Dev (precisa de Node)
cd frontend && npm install && npm run dev

# Docker (build completo)
docker compose build frontend
docker compose up frontend
# Acessar http://localhost
```