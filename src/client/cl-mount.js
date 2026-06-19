import { initRuntime, setRenderToken } from './cl-runtime.js';

export async function mount(selector, config) {
  const target = document.querySelector(selector);
  if (!target) {
    console.error(`cl-s3r mount: target "${selector}" not found`);
    return;
  }

  const apiPrefix = config.apiPrefix || '';

  try {
    const response = await fetch(`${apiPrefix}/api/render`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        component: config.component,
        props: config.props || {}
      })
    });

    if (!response.ok) {
      const contentType = response.headers.get('Content-Type') || '';
      if (contentType.includes('text/html')) {
        const html = await response.text();
        const parser = new DOMParser();
        const newDoc = parser.parseFromString(html, 'text/html');
        document.head.innerHTML = newDoc.head.innerHTML;
        document.body.innerHTML = newDoc.body.innerHTML;
      } else {
        console.error(`cl-s3r mount failed: ${response.status}`);
      }
      return;
    }

    const result = await response.json();
    if (result['render-token']) {
      setRenderToken(result['render-token']);
    }
    if (result.html) {
      target.innerHTML = result.html;
      const rootEl = target.firstElementChild;
      if (rootEl) {
        const redirect = rootEl.getAttribute('data-redirect');
        if (redirect) {
          window.location.href = redirect;
          return;
        }
      }
    }

    initRuntime(selector, { apiPrefix, tokenExpired: config.tokenExpired });
  } catch (error) {
    console.error('cl-s3r mount failed:', error);
  }
}
