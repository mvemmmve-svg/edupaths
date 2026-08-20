// web/flutter_service_worker.js  (upload as flutter_service_worker.js)
// Network-first: users always get the latest version after a deploy.
// Saved passwords live in the browser's credential manager — never affected.

'use strict';

// This cache name changes automatically when index.html loads with a new ?v=
// because the registration URL changes, forcing the browser to install a fresh worker.
var CACHE_NAME = 'edupaths-cache-v1';

self.addEventListener('message', function(event) {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

self.addEventListener('install', function(event) {
  self.skipWaiting();
});

self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(names) {
      return Promise.all(
        names
          .filter(function(name) { return name !== CACHE_NAME; })
          .map(function(name) { return caches.delete(name); })
      );
    }).then(function() {
      return self.clients.claim();
    })
  );
});

self.addEventListener('fetch', function(event) {
  var url = new URL(event.request.url);

  // Never intercept Supabase calls or cross-origin requests
  if (url.hostname !== self.location.hostname) {
    return;
  }

  // index.html and service worker: always fetch from network, never cache
  if (
    url.pathname === '/' ||
    url.pathname === '/index.html' ||
    url.pathname.includes('flutter_service_worker')
  ) {
    event.respondWith(fetch(event.request));
    return;
  }

  // Everything else: network-first, cache as fallback for offline
  event.respondWith(
    fetch(event.request)
      .then(function(response) {
        if (!response || response.status !== 200 || response.type !== 'basic') {
          return response;
        }
        var toCache = response.clone();
        caches.open(CACHE_NAME).then(function(cache) {
          cache.put(event.request, toCache);
        });
        return response;
      })
      .catch(function() {
        return caches.match(event.request);
      })
  );
});
