/* Completion alerts only: no images, grades, credentials or push service. */
(() => {
  'use strict';
  let registration = null;
  let originalTitle = null;
  let analyzeVisible = false;
  const viewingAnalyze = () => analyzeVisible && !document.hidden && document.hasFocus();
  const options = () => ({body: 'The analysis is done', tag: 'abakascan-analysis',
    icon: new URL('icons/Icon-192.png', document.baseURI).href,
    data: {url: location.href}});
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden && originalTitle !== null) {
      document.title = originalTitle;
      originalTitle = null;
    }
  });
  window.abakascanNotifications = {
    setAnalyzeVisible(visible) { analyzeVisible = !!visible; },
    async prepare() {
      try {
        if (!window.isSecureContext || !('Notification' in window)) return;
        // Invoke immediately in the Analyze button gesture, before any await.
        const permission = Notification.permission === 'default'
          ? Notification.requestPermission() : Promise.resolve(Notification.permission);
        if (await permission !== 'granted') return;
        if ('serviceWorker' in navigator) {
          registration = await navigator.serviceWorker.register(
            new URL('analysis_notification_sw.js', document.baseURI).href,
            {scope: new URL('analysis-notifications/', document.baseURI).pathname});
        }
      } catch (_) { /* Permission/worker support is optional. */ }
    },
    async done() {
      // Evaluate where the user is NOW, not where the analysis started.
      if (viewingAnalyze()) return;
      if (document.hidden) {
        originalTitle ??= document.title;
        document.title = 'Analysis done · ABAKASCAN';
      }
      try {
        if (!('Notification' in window) || Notification.permission !== 'granted') return;
        if (registration) {
          // A fresh worker may still be installing. Wait for that worker only.
          if (!registration.active) {
            const worker = registration.installing || registration.waiting;
            if (worker && worker.state !== 'activated') {
              await new Promise((resolve, reject) => {
                const timeout = setTimeout(() => reject(new Error('Worker activation timeout')), 10000);
                const changed = () => {
                  if (worker.state === 'activated' || worker.state === 'redundant') {
                    clearTimeout(timeout); worker.removeEventListener('statechange', changed);
                    if (worker.state === 'activated') resolve(); else reject(new Error('Worker unavailable'));
                  }
                };
                worker.addEventListener('statechange', changed); changed();
              });
            }
          }
          if (viewingAnalyze()) return;
          await registration.showNotification('ABAKASCAN', options());
          return;
        }
      } catch (_) { /* Try desktop browser notifications below. */ }
      try {
        if ('Notification' in window && Notification.permission === 'granted') {
          if (viewingAnalyze()) return;
          const alert = new Notification('ABAKASCAN', options());
          alert.onclick = () => { window.focus(); alert.close(); };
        }
      } catch (_) { /* Tab title is still available when unsupported/blocked. */ }
    }
  };
})();
