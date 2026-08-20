// Drop this file into web/ folder as flutter_service_worker.js
// This forces the browser to ALWAYS check the network for the latest version
// instead of serving stale cached files.

'use strict';

const CACHE_NAME = 'flutter-app-cache';

self.addEventListener('install', function(event) {
  self.skipWaiting();
});

self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.map(function(cacheName) {
          // Delete ALL old caches on every activate
          return caches.delete(cacheName);
        })
      );
    }).then(function() {
      return self.clients.claim();
    })
  );
});

self.addEventListener('fetch', function(event) {
  // Network-first strategy: always try network, fall back to cache
  event.respondWith(
    fetch(event.request).then(function(response) {
      // Only cache valid responses
      if (!response || response.status !== 200 || response.type !== 'basic') {
        return response;
      }
      const responseToCache = response.clone();
      caches.open(CACHE_NAME).then(function(cache) {
        cache.put(event.request, responseToCache);
      });
      return response;
    }).catch(function() {
      // Network failed - try cache as fallback
      return caches.match(event.request);
    })
  );
});
