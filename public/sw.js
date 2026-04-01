const CACHE_NAME = 'pluribeauty-runtime-v2';
const APP_ASSETS = ['/manifest.webmanifest', '/favicon.svg', '/favicon.ico'];

self.addEventListener('install', (event) => {
	event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
	event.waitUntil(
		caches
			.keys()
			.then((keys) => Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))))
			.then(() => self.clients.claim()),
	);
});

self.addEventListener('fetch', (event) => {
	if (event.request.method !== 'GET') return;

	const url = new URL(event.request.url);
	if (url.origin !== self.location.origin) return;

	if (event.request.mode === 'navigate') {
		event.respondWith(
			fetch(event.request)
				.then((response) => {
					const copy = response.clone();
					caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
					return response;
				})
				.catch(async () => {
					const cached = await caches.match(event.request);
					return cached || Response.error();
				}),
		);
		return;
	}

	if (['script', 'style', 'image', 'font'].includes(event.request.destination)) {
		event.respondWith(
			caches.match(event.request).then((cached) => {
				const networkFetch = fetch(event.request)
					.then((response) => {
						const copy = response.clone();
						caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
						return response;
					})
					.catch(() => cached);

				return cached || networkFetch;
			}),
		);
	}
});
