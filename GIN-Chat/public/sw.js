// ==============================================================================
// GIN-Chat Service Worker (PWA & Web Push Notification Handler)
// Version: v0.3.0
// ==============================================================================

const CACHE_NAME = "gin-chat-v030";
const ASSETS_TO_CACHE = [
  "/",
  "/index.html",
  "/manifest.json",
  "/favicon.svg",
  "/favicon.ico",
  "/icons/icon-192.png",
  "/icons/icon-512.png",
  "/icons/icon-maskable-192.png",
  "/icons/icon-maskable-512.png",
  "/icons/apple-touch-icon.png"
];

// 1. Install & Cache
self.addEventListener("install", (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS_TO_CACHE).catch((err) => {
        console.warn("SW pre-cache non-fatal:", err);
      });
    })
  );
});

// 2. Activate & Purge Old Caches
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// 3. Network / Cache Fetch Handler
self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);

  if (event.request.method !== "GET" || url.pathname.startsWith("/api/") || url.pathname.startsWith("/socket.io/")) {
    return;
  }

  if (event.request.mode === "navigate") {
    event.respondWith(
      fetch(event.request).catch(() => caches.match("/index.html"))
    );
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        fetch(event.request).then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, networkResponse));
          }
        }).catch(() => {});
        return cachedResponse;
      }
      return fetch(event.request).then((networkResponse) => {
        if (networkResponse && networkResponse.status === 200 && networkResponse.type === "basic") {
          const responseToCache = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, responseToCache));
        }
        return networkResponse;
      });
    })
  );
});

// 4. Web Push Notification Handler (iOS Safari PWA, Android, Desktop)
self.addEventListener("push", (event) => {
  let data = {};
  if (event.data) {
    try {
      data = event.data.json();
    } catch (e) {
      data = { title: "GIN-Chat", body: event.data.text() };
    }
  }

  const title = data.title || "GIN-Chat";
  const isCall = (data.data && data.data.type === "incoming_call") || (data.tag && data.tag.startsWith("call_"));

  const options = {
    body: data.body || "Новое сообщение в чате",
    icon: data.icon || "/icons/icon-192.png",
    badge: data.badge || "/icons/icon-192.png",
    tag: data.tag || (isCall ? "call_incoming" : "gin-chat-msg"),
    renotify: data.renotify !== undefined ? data.renotify : true,
    requireInteraction: isCall, // keep on screen for incoming call
    silent: false,
    vibrate: isCall ? [300, 100, 300, 100, 300, 100, 400] : [200, 100, 200],
    data: data.data || { url: "/" }
  };

  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

// 5. Notification Click Handler (Focus window or open new window)
self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const notifData = event.notification.data || {};
  const targetUrl = notifData.url || "/";

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      // Find open window of GIN-Chat
      for (const client of clientList) {
        if (client.url && client.url.includes(self.location.origin) && "focus" in client) {
          if ("navigate" in client && notifData.chatId) {
            client.navigate(targetUrl);
          }
          return client.focus();
        }
      }
      // If no open window, open a new one
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});
