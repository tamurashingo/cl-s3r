/**
 * CLComponent - Base Custom Element class for cl-s3r components
 */
export class CLComponent extends HTMLElement {
  constructor() {
    super();
  }

  connectedCallback() {
    // Initialization when the component is connected to the DOM (reserved for future use)
  }

  /**
   * Parse and return the current state from the data-state attribute.
   */
  get state() {
    const stateStr = this.getAttribute('data-state');
    try {
      return stateStr ? JSON.parse(stateStr) : {};
    } catch (e) {
      console.error('Failed to parse data-state:', e);
      return {};
    }
  }

  /**
   * Get the component name from the tag name.
   */
  get componentName() {
    return this.tagName.toLowerCase();
  }
}

// Register as a custom element
if (!customElements.get('cl-component')) {
  customElements.define('cl-component', CLComponent);
}
