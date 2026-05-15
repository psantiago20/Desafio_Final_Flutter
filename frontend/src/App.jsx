import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './contexts/AuthContext';
import Navbar from './components/Navbar';
import Sidebar from './components/Sidebar';
import RightSidebar from './components/RightSidebar';
import BottomNav from './components/BottomNav';
import AuthPage from './pages/AuthPage';
import FeedPage from './pages/FeedPage';
import ExplorePage from './pages/ExplorePage';
import ProfilePage from './pages/ProfilePage';
import ProfileEditPage from './pages/ProfileEditPage';
import PostDetailPage from './pages/PostDetailPage';
import GroupsPage from './pages/GroupsPage';
import GroupDetailPage from './pages/GroupDetailPage';
import LibraryPage from './pages/LibraryPage';
import MentorshipPage from './pages/MentorshipPage';
import MentorshipSessionPage from './pages/MentorshipSessionPage';
import NotificationsPage from './pages/NotificationsPage';
import SettingsPage from './pages/SettingsPage';
import AdminPage from './pages/AdminPage';
import MessagesPage from './pages/MessagesPage';
import ConversationPage from './pages/ConversationPage';

function ProtectedRoute({ children }) {
  const { isAuthenticated, isLoading } = useAuth();
  if (isLoading) {
    return (
      <div className="loading-container" style={{ minHeight: '100vh' }}>
        <div className="spinner spinner-lg"></div>
      </div>
    );
  }
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return children;
}

function PublicRoute({ children }) {
  const { isAuthenticated, isLoading } = useAuth();
  if (isLoading) {
    return (
      <div className="loading-container" style={{ minHeight: '100vh' }}>
        <div className="spinner spinner-lg"></div>
      </div>
    );
  }
  if (isAuthenticated) return <Navigate to="/feed" replace />;
  return children;
}

function AppLayout({ children }) {
  return (
    <>
      <Navbar />
      <div className="app-layout" id="app-layout">
        <Sidebar />
        <main id="main-content">{children}</main>
        <RightSidebar />
      </div>
      <BottomNav />
    </>
  );
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<PublicRoute><AuthPage /></PublicRoute>} />
      <Route path="/register" element={<PublicRoute><AuthPage /></PublicRoute>} />
      <Route path="/" element={<ProtectedRoute><AppLayout><FeedPage /></AppLayout></ProtectedRoute>} />
      <Route path="/feed" element={<ProtectedRoute><AppLayout><FeedPage /></AppLayout></ProtectedRoute>} />
      <Route path="/explore" element={<ProtectedRoute><AppLayout><ExplorePage /></AppLayout></ProtectedRoute>} />
      <Route path="/profile" element={<ProtectedRoute><AppLayout><ProfilePage /></AppLayout></ProtectedRoute>} />
      <Route path="/profile/edit" element={<ProtectedRoute><AppLayout><ProfileEditPage /></AppLayout></ProtectedRoute>} />
      <Route path="/profile/:id" element={<ProtectedRoute><AppLayout><ProfilePage /></AppLayout></ProtectedRoute>} />
      <Route path="/post/:id" element={<ProtectedRoute><AppLayout><PostDetailPage /></AppLayout></ProtectedRoute>} />
      <Route path="/groups" element={<ProtectedRoute><AppLayout><GroupsPage /></AppLayout></ProtectedRoute>} />
      <Route path="/groups/:id" element={<ProtectedRoute><AppLayout><GroupDetailPage /></AppLayout></ProtectedRoute>} />
      <Route path="/library" element={<ProtectedRoute><AppLayout><LibraryPage /></AppLayout></ProtectedRoute>} />
      <Route path="/mentorship" element={<ProtectedRoute><AppLayout><MentorshipPage /></AppLayout></ProtectedRoute>} />
      <Route path="/mentorship/:id" element={<ProtectedRoute><AppLayout><MentorshipSessionPage /></AppLayout></ProtectedRoute>} />
      <Route path="/notifications" element={<ProtectedRoute><AppLayout><NotificationsPage /></AppLayout></ProtectedRoute>} />
      <Route path="/settings" element={<ProtectedRoute><AppLayout><SettingsPage /></AppLayout></ProtectedRoute>} />
      <Route path="/admin" element={<ProtectedRoute><AppLayout><AdminPage /></AppLayout></ProtectedRoute>} />
      <Route path="/messages" element={<ProtectedRoute><AppLayout><MessagesPage /></AppLayout></ProtectedRoute>} />
      <Route path="/messages/:id" element={<ProtectedRoute><AppLayout><ConversationPage /></AppLayout></ProtectedRoute>} />
      <Route path="*" element={<Navigate to="/feed" replace />} />
    </Routes>
  );
}
