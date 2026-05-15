import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './App';
import { AuthProvider } from './contexts/AuthContext';
import { UIProvider } from './contexts/UIContext';
import { ThemeProvider } from './contexts/ThemeContext';
import '../css/reset.css';
import '../css/themes.css';
import '../css/main.css';
import '../css/layout.css';
import '../css/components.css';
import '../css/responsive.css';
import '../css/pages/auth.css';
import '../css/pages/feed.css';
import '../css/pages/profile.css';
import '../css/pages/groups.css';
import '../css/pages/library.css';
import '../css/pages/mentorship.css';
import '../css/pages/messages.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <ThemeProvider>
        <AuthProvider>
          <UIProvider>
            <App />
          </UIProvider>
        </AuthProvider>
      </ThemeProvider>
    </BrowserRouter>
  </React.StrictMode>
);
