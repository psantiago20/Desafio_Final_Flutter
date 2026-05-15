import router from './router.js';
import authStore from './state/auth.store.js';
import { isAuthenticated, refreshSession } from './services/auth.service.js';
import { initTheme } from './services/theme.service.js';
import Navbar from './components/Navbar.js';
import Sidebar from './components/Sidebar.js';
import RightSidebar from './components/RightSidebar.js';
import BottomNav from './components/BottomNav.js';

import AuthPage from './pages/AuthPage.js';
import FeedPage from './pages/FeedPage.js';
import ExplorePage from './pages/ExplorePage.js';
import ProfilePage from './pages/ProfilePage.js';
import ProfileEditPage from './pages/ProfileEditPage.js';
import PostDetailPage from './pages/PostDetailPage.js';
import GroupsPage from './pages/GroupsPage.js';
import GroupDetailPage from './pages/GroupDetailPage.js';
import LibraryPage from './pages/LibraryPage.js';
import MentorshipPage from './pages/MentorshipPage.js';
import MentorshipSessionPage from './pages/MentorshipSessionPage.js';
import NotificationsPage from './pages/NotificationsPage.js';
import SettingsPage from './pages/SettingsPage.js';
import AdminPage from './pages/AdminPage.js';
import MessagesPage from './pages/MessagesPage.js';
import ConversationPage from './pages/ConversationPage.js';

function initApp() {
  initTheme();

  let navbar, sidebar, rightSidebar, bottomNav;

  function mountLayout() {
    const navEl = document.getElementById('navbar');
    const sidebarEl = document.getElementById('left-sidebar');
    const rightEl = document.getElementById('right-sidebar');
    const bottomEl = document.getElementById('bottom-nav');

    if (navEl) {
      navbar = new Navbar({ container: navEl });
      navbar.mount(navEl);
    }
    if (sidebarEl) {
      sidebar = new Sidebar({ container: sidebarEl });
      sidebar.mount(sidebarEl);
    }
    if (rightEl) {
      rightSidebar = new RightSidebar({ container: rightEl });
      rightSidebar.mount(rightEl);
    }
    if (bottomEl) {
      bottomNav = new BottomNav({ container: bottomEl });
      bottomNav.mount(bottomEl);
    }
  }

  function showApp() {
    document.getElementById('loading-spinner').style.display = 'none';
    const layout = document.getElementById('app-layout');
    if (layout) layout.style.display = 'grid';
    mountLayout();
  }

  function hideApp() {
    const layout = document.getElementById('app-layout');
    if (layout) layout.style.display = 'none';
    document.getElementById('loading-spinner').style.display = 'flex';
  }

  function isAuthRoute(path) {
    return path === '/login' || path === '/register' || path.startsWith('/auth');
  }

  router.addGuard((path) => {
    const authenticated = authStore.get('isAuthenticated');

    if (authenticated && isAuthRoute(path)) {
      window.location.hash = '#/feed';
      return false;
    }

    if (!authenticated && !isAuthRoute(path)) {
      window.location.hash = '#/login';
      return false;
    }

    if (authenticated && !isAuthRoute(path)) {
      showApp();
    } else {
      hideApp();
    }

    return true;
  });

    router.addRoute('/login', AuthPage);
    router.addRoute('/register', AuthPage);
    router.addRoute('/feed', FeedPage);
    router.addRoute('/explore', ExplorePage);
    router.addRoute('/profile', ProfilePage);
    router.addRoute('/profile/edit', ProfileEditPage);
    router.addRoute('/profile/:id', ProfilePage);
    router.addRoute('/post/:id', PostDetailPage);
    router.addRoute('/groups', GroupsPage);
    router.addRoute('/groups/:id', GroupDetailPage);
    router.addRoute('/library', LibraryPage);
    router.addRoute('/mentorship', MentorshipPage);
    router.addRoute('/mentorship/:id', MentorshipSessionPage);
    router.addRoute('/notifications', NotificationsPage);
    router.addRoute('/settings', SettingsPage);
    router.addRoute('/admin', AdminPage);
    router.addRoute('/messages', MessagesPage);
    router.addRoute('/messages/:id', ConversationPage);
    router.addRoute('/404', AuthPage);

  authStore.subscribe(() => {
    if (navbar) {
      navbar.render();
    }
  });

  async function bootstrap() {
    const token = authStore.get('accessToken');
    if (token) {
      try {
        await refreshSession();
      } catch {
      }
    }
    authStore.set({ isLoading: false });
    router.start();
  }

  bootstrap();
}

document.addEventListener('DOMContentLoaded', initApp);
