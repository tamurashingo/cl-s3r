import { CLComponent } from './cl-component.js';
import { initRuntime } from './cl-runtime.js';

// Initialize runtime after DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  console.log('cl-s3r runtime initializing...');
  initRuntime();
});

export { CLComponent, initRuntime };
