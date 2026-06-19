/**
 * cl-runtime - State collection and server communication runtime
 */

import { morphElement } from './cl-morph.js';

let _renderToken = null;

export function setRenderToken(token) {
  _renderToken = token;
}

function handleTokenExpired(config) {
  const reload = () => window.location.reload();
  if (!config || config.mode === 'reload') {
    reload();
  } else if (config.mode === 'alert') {
    alert(config.message || 'Your session has expired.');
    reload();
  } else if (config.mode === 'confirm') {
    if (confirm(config.message || 'Your session has expired. Reload the page?')) {
      reload();
    }
  }
}

/**
 * Recursively collect component states from the given root element.
 * @param {HTMLElement} element - The element to start traversal from
 * @returns {Object|null} Hierarchical state object
 */
export function collectStates(element) {
  // Identify components by data-state attribute or hyphenated tag name
  const isComponent = element.hasAttribute('data-state') || element.tagName.includes('-');

  if (!isComponent) {
    // Not a component — search children
    for (const child of element.children) {
      const result = collectStates(child);
      if (result) return result; // Return the first component found (for root lookup)
    }
    return null;
  }

  // Build the state node for this component
  const node = {
    component: element.getAttribute('data-component') || element.tagName.toLowerCase(),
    state: {},
    children: []
  };

  // Parse own state
  const stateStr = element.getAttribute('data-state');
  if (stateStr) {
    try {
      node.state = JSON.parse(stateStr);
    } catch (e) {
      console.error(`Failed to parse state for ${node.component}:`, e);
    }
  }

  // Attach id if present
  const id = element.getAttribute('id');
  if (id) {
    node.id = id;
  }

  // Attach component-id if present
  const componentId = element.getAttribute('data-component-id');
  if (componentId) {
    node['component-id'] = componentId;
  }

  // Recursively collect child components
  for (const child of element.children) {
    collectChildStates(child, node.children);
  }

  return node;
}

/**
 * Recursively find child components in the element tree and append to the list.
 * @param {HTMLElement} element
 * @param {Array} childrenList
 */
function collectChildStates(element, childrenList) {
  const isComponent = element.hasAttribute('data-state') || element.tagName.includes('-');

  if (isComponent) {
    const node = {
      component: element.getAttribute('data-component') || element.tagName.toLowerCase(),
      state: {},
      children: []
    };

    const stateStr = element.getAttribute('data-state');
    if (stateStr) {
      try {
        node.state = JSON.parse(stateStr);
      } catch (e) {
        console.error(`Failed to parse state for ${node.component}:`, e);
      }
    }

    const id = element.getAttribute('id');
    if (id) {
      node.id = id;
    }

    const componentId = element.getAttribute('data-component-id');
    if (componentId) {
      node['component-id'] = componentId;
    }

    // Continue searching for nested child components
    for (const child of element.children) {
      collectChildStates(child, node.children);
    }

    childrenList.push(node);
  } else {
    // Not a component — continue traversing its children
    for (const child of element.children) {
      collectChildStates(child, childrenList);
    }
  }
}

/**
 * Send an action and the current state tree to the server.
 * @param {Array} action - Action descriptor array
 * @param {HTMLElement} componentElement - The component that owns the action
 * @param {HTMLElement} rootElement - The root component element (for state collection)
 * @param {Object} options
 */
export async function sendAction(action, componentElement, rootElement,
                                 { apiPrefix = '', tokenExpired = null } = {}) {
  const state = collectStates(rootElement);
  const payload = {
    action,
    state,
    'component-id': componentElement.getAttribute('data-component-id') || undefined,
    'render-token': _renderToken
  };

  try {
    const response = await fetch(`${apiPrefix}/action`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    if (response.status === 409) {
      handleTokenExpired(tokenExpired);
      return;
    }

    if (!response.ok) throw new Error('Network response was not ok');

    const result = await response.json();
    if (result.html) {
      const temp = document.createElement('div');
      temp.innerHTML = result.html;
      const newElement = temp.firstElementChild;

      if (newElement) {
        const redirect = newElement.getAttribute('data-redirect');
        if (redirect) {
          window.location.href = redirect;
          return;
        }
      }

      if (newElement && componentElement.parentNode) {
        morphElement(componentElement, newElement);
        if (result.state) {
          componentElement.setAttribute('data-state', JSON.stringify(result.state));
        }
      } else {
        // Fallback: componentElement detached from DOM
        componentElement.innerHTML = result.html;
        if (result.state) {
          componentElement.setAttribute('data-state', JSON.stringify(result.state));
        }
      }
    }
  } catch (error) {
    console.error('Failed to send action:', error);
  }
}

/**
 * Find the component element that should handle the action.
 * Walks up the component tree to find the nearest ancestor with non-empty state,
 * skipping stateless presentational components (data-state="{}").
 * Falls back to the root element if no stateful component is found.
 */
function findActionTarget(element, mountContainer) {
  let el = element.closest('[data-component]');
  while (el && el !== mountContainer) {
    const stateStr = el.getAttribute('data-state');
    let isEmpty = true;
    if (stateStr) {
      try {
        const s = JSON.parse(stateStr);
        isEmpty = !s || (typeof s === 'object' && !Array.isArray(s) && Object.keys(s).length === 0);
      } catch (e) {
        isEmpty = false;
      }
    }
    if (!isEmpty) return el;
    const parent = el.parentElement;
    el = parent ? parent.closest('[data-component]') : null;
  }
  return mountContainer.firstElementChild;
}

/**
 * Initialize event delegation (click and submit handlers).
 * Actions are routed to the nearest stateful ancestor component element.
 */
export function initRuntime(rootSelector = 'body', { apiPrefix = '', tokenExpired = null } = {}) {
  const mountContainer = document.querySelector(rootSelector);

  mountContainer.addEventListener('click', (event) => {
    const trigger = event.target.closest('[data-on-click]');
    if (!trigger) return;
    try {
      const action = JSON.parse(trigger.getAttribute('data-on-click'));
      const owningComp = findActionTarget(trigger, mountContainer);
      const root = mountContainer.firstElementChild;
      if (root) sendAction(action, owningComp, root, { apiPrefix, tokenExpired });
    } catch (e) {
      console.error('Failed to parse action JSON:', e);
    }
  });

  mountContainer.addEventListener('submit', (event) => {
    const form = event.target.closest('[data-on-submit]');
    if (!form) return;
    event.preventDefault();
    try {
      const action = JSON.parse(form.getAttribute('data-on-submit'));
      const formData = Object.fromEntries(new FormData(form).entries());
      action.push(formData);
      const owningComp = findActionTarget(form, mountContainer);
      const root = mountContainer.firstElementChild;
      if (root) sendAction(action, owningComp, root, { apiPrefix, tokenExpired });
      form.reset();
    } catch (e) {
      console.error('Failed to parse submit action JSON:', e);
    }
  });
}
