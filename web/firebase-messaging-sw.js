// web/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.11.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.11.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAVPMu0nv3fk0OsmWlVQAYN6L-__K4Z0GA",
  authDomain: "timretail-457509.firebaseapp.com",
  projectId: "timretail-457509",
  storageBucket: "timretail-457509.appspot.com",
  messagingSenderId: "755445236888",
  appId: "1:755445236888:web:aca82dc3e1273352f97ced"
});

const messaging = firebase.messaging();
