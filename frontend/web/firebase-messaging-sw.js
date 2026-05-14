// Firebase Cloud Messaging Service Worker
// Necessário para receber notificações push no navegador

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCox2SIJip-wPQ28WpFUyYjZWIF3oJSl5w',
  appId: '1:302551957750:web:3d409d0ef08c12d5396cd7',
  messagingSenderId: '302551957750',
  projectId: 'desafio-final-05',
  authDomain: 'desafio-final-05.firebaseapp.com',
  storageBucket: 'desafio-final-05.firebasestorage.app',
  measurementId: 'G-Y3H9D8EHQT',
});

const messaging = firebase.messaging();

// Tratar mensagens em background
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Mensagem recebida em background:', payload);

  const notificationTitle = payload.notification?.title || 'Nova Notificação';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// Ao clicar na notificação, abrir/focar a janela da app
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (const client of clientList) {
        if (client.url && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
