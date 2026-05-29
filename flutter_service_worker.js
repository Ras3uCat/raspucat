'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"bingequest/content/index.html": "5f6aacc4f3f21ecf54c0aee4b2e206d0",
"bingequest/profile/index.html": "f928022699a4561b34b100061f1fe118",
"bingequest/playlist/index.html": "c0edeee13c02606daeb03bdfdbed43af",
"version.json": "cb8dd4a21077fcd2d4121ed0128e6ecf",
"icons/Icon-maskable-192.png": "980913cbf3e887c423c356b7d23428aa",
"icons/Icon-512.png": "f83dca481def1fce2006a6d1eb243f8e",
"icons/Icon-maskable-512.png": "da8f93103ae5f66e3d166b1767802678",
"icons/Icon-192.png": "67c3c79c88cbde325b4a44796f45a27f",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"legal/bingequest/index.html": "29b2c6c54908d878e614bb4948dc8599",
"404.html": "d6f85ac73e83fb6cd6d44ca0e1f01557",
"favicon.svg": "20067aff097a215ae9a08a8f36126d99",
".well-known/assetlinks.json": "b54fd7ee3b8792c7c19a121c3ca256eb",
".well-known/apple-app-site-association": "f0fecc8e4349be32e13b0d11ae788e8c",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "e05f4b558cb56522148a6b79ea943d2d",
"manifest.json": "b903179230055979c0f8f0b0020c0492",
"index.html": "b7c2dc6b3e16c24ad2f842cf8e64fb09",
"/": "b7c2dc6b3e16c24ad2f842cf8e64fb09",
"favicon.png": "5d84811a8fc9ca44c5e91135d7500070",
"main.dart.js": "ead456584ba70f918549052998ee1c94",
"assets/NOTICES": "af2ce44b342cfe4da580c05b479089ed",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "39e38dae824e4ebdf1e4de28ecead20b",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "00b5cb242eebda53ad6210d6232ca9c4",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "55098074db1771909bb1e9e1170f9640",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/AssetManifest.bin": "2f3172ffc3bc4941f538d607ef47e1b6",
"assets/AssetManifest.bin.json": "e78d1e98cf3592627ff60744fa7b53f4",
"assets/AssetManifest.json": "c9230639c4132b7199b20bef6c703e39",
"assets/FontManifest.json": "5a32d4310a6f5d9a6b651e75ba0d7372",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/fonts/MaterialIcons-Regular.otf": "787507bd4786859706298a60120165d2",
"assets/assets/images/logos/raspucat_bimi.svg": "d82361c190a852409dec84c1ebdfc9b1",
"assets/assets/images/logos/raspucat_gradient.png": "783c86011e397c237c9951111c6a49c5",
"assets/assets/images/logos/raspucat_512.png": "9a270910d4f1771b5b13362a60367088",
"assets/assets/images/logos/raspucat_white.svg": "2931709e466343f8f8b73a47161106a6",
"assets/assets/images/logos/raspucat_black.svg": "20067aff097a215ae9a08a8f36126d99",
"assets/assets/images/projects/bingequest_ios_2.png": "26aa2399e52b77e30e2210e42d106c7c",
"assets/assets/images/projects/bingequest_ios_4.png": "ed715fbe3c047de708dae5eee5df9737",
"assets/assets/images/projects/bingequest_play_3.png": "c23211a018e99da3009a3230df2edf9c",
"assets/assets/images/projects/dashing_beard_co_hero.gif": "c3b2dbe082a0e54a5b47572fda3e3d9b",
"assets/assets/images/projects/red_dot_entertainment_beats.png": "7a7f045f319aeae8329e59c040d81f37",
"assets/assets/images/projects/dashing_beard_co.png": "263482dccdeb40e28d388f1efe981a36",
"assets/assets/images/projects/bingequest_play_2.png": "16d437a1c22cc8376caaab0d034b757b",
"assets/assets/images/projects/red_dot_entertainment_hero.gif": "eaf168f31379830349eedd40b253c256",
"assets/assets/images/projects/red_dot_entertainment_book_session.png": "73206d067374ee7675f988abb169faf5",
"assets/assets/images/projects/red_dot_entertainment_hero.png": "c8c9f780fb5a1a530696c2637069e4bc",
"assets/assets/images/projects/bingequest_ios_3.png": "58a8c0b09c65bbafc02b572e5f8567f8"};
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
