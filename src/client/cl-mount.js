import { initRuntime } from './cl-runtime.js';

export async function mount(selector, config) {
  const target = document.querySelector(selector);
  if (!target) {
    console.error(`cl-s3r mount: target "${selector}" not found`);
    return;
  }

  try {
    const response = await fetch('/api/render', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        component: config.component,
        props: config.props || {}
      })
    });

    if (!response.ok) {
      throw new Error(`Server responded with ${response.status}`);
    }

    const result = await response.json();
    if (result.html) {
      target.innerHTML = result.html;
    }

    initRuntime(selector);
  } catch (error) {
    console.error('cl-s3r mount failed:', error);
  }
}
