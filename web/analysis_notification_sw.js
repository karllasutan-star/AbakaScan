self.addEventListener('install', event => { event.waitUntil(self.skipWaiting()); });
self.addEventListener('notificationclick', event => {
  event.notification.close();
  event.waitUntil((async () => {
    const target = new URL(event.notification.data?.url || self.registration.scope);
    if (target.origin !== self.location.origin) return;
    const windows = await self.clients.matchAll({type: 'window', includeUncontrolled: true});
    for (const client of windows) {
      const url = new URL(client.url);
      if (url.origin === target.origin && url.pathname === target.pathname) {
        await client.focus(); return;
      }
    }
    await self.clients.openWindow(target.href);
  })());
});
