'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"manifest.json": "b903179230055979c0f8f0b0020c0492",
"404.html": "d6f85ac73e83fb6cd6d44ca0e1f01557",
"version.json": "cb8dd4a21077fcd2d4121ed0128e6ecf",
"legal/bingequest/index.html": "a8ce488dca20527f6f4d90b273b5c4b5",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"index.html": "b7c2dc6b3e16c24ad2f842cf8e64fb09",
"/": "b7c2dc6b3e16c24ad2f842cf8e64fb09",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"icons/Icon-192.png": "67c3c79c88cbde325b4a44796f45a27f",
"icons/Icon-512.png": "f83dca481def1fce2006a6d1eb243f8e",
"icons/Icon-maskable-512.png": "da8f93103ae5f66e3d166b1767802678",
"icons/Icon-maskable-192.png": "980913cbf3e887c423c356b7d23428aa",
"assets/AssetManifest.bin": "407a0b518c804dc22857b90aefa1d6d1",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "39e38dae824e4ebdf1e4de28ecead20b",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "730c82858a67b4a98f21b566f9a1cb33",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "00b5cb242eebda53ad6210d6232ca9c4",
"assets/FontManifest.json": "5a32d4310a6f5d9a6b651e75ba0d7372",
"assets/NOTICES": "af2ce44b342cfe4da580c05b479089ed",
"assets/AssetManifest.json": "4b5c51560b5d854cae3f7dadd4ffa44a",
"assets/assets/images/projects/red_dot_entertainment_hero.gif": "f40757ef63e3372b4cd858573ae0bf4b",
"assets/assets/images/projects/red_dot_entertainment_booking.gif": "da713f80b1ca7022d373ff3eb9a57018",
"assets/assets/images/projects/dashing_beard_co_hero.gif": "c3b2dbe082a0e54a5b47572fda3e3d9b",
"assets/assets/images/projects/red_dot_entertainment.png": "cc3a21704ed5957b0686599751d7fd65",
"assets/assets/images/projects/dashing_beard_co.png": "263482dccdeb40e28d388f1efe981a36",
"assets/assets/images/logos/raspucat_512.png": "9a270910d4f1771b5b13362a60367088",
"assets/assets/images/logos/raspucat_black.svg": "20067aff097a215ae9a08a8f36126d99",
"assets/assets/images/logos/raspucat_bimi.svg": "d82361c190a852409dec84c1ebdfc9b1",
"assets/assets/images/logos/raspucat_gradient.png": "783c86011e397c237c9951111c6a49c5",
"assets/assets/images/logos/raspucat_white.svg": "2931709e466343f8f8b73a47161106a6",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/fonts/MaterialIcons-Regular.otf": "92921cb80818d8acc20ea7b207c610d1",
"assets/AssetManifest.bin.json": "7adaee336f3f56d9ab0cae10654fcdb3",
"flutter_bootstrap.js": "56ecd931ad6734e98cdbfd7e364d37c5",
"favicon.png": "5d84811a8fc9ca44c5e91135d7500070",
"favicon.svg": "20067aff097a215ae9a08a8f36126d99",
"main.dart.js": "1d4f3c176913e0ae5a4c7317c298e8cb"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
