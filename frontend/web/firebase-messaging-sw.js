importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCox2SIJip-wPQ28WpFUyYjZWIF3oJSl5w",
  authDomain: "desafio-final-05.firebaseapp.com",
  projectId: "desafio-final-05",
  storageBucket: "desafio-final-05.firebasestorage.app",
  messagingSenderId: "302551957750",
  appId: "1:302551957750:web:3d409d0ef08c12d5396cd7"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
