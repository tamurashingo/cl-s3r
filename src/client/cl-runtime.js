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
 * Collect the state of every component under ROOTELEMENT.
 *
 * The result is flat -- component-id -> state -- because a component-id encodes
 * the component's position in the tree, so the server can rebuild the shape from
 * the ids alone. Components with no state of their own are left out entirely;
 * sending an envelope for them (name, empty state, empty children, id) was most
 * of the payload.
 *
 * @param {HTMLElement} rootElement
 * @returns {Object} component-id -> state
 */
export function collectStates(rootElement) {
  const states = {};

  const visit = (element) => {
    const id = element.getAttribute('data-component-id');
    const raw = element.getAttribute('data-state');
    if (id && raw) {
      try {
        const state = JSON.parse(raw);
        if (state && typeof state === 'object' && Object.keys(state).length > 0) {
          states[id] = state;
        }
      } catch (e) {
        console.error(`Failed to parse state for ${id}:`, e);
      }
    }
    for (const child of element.children) visit(child);
  };

  visit(rootElement);
  return states;
}

/**
 * Send an action and the collected component state to the server.
 * @param {Array} action - Action descriptor array
 * @param {HTMLElement} componentElement - The component that owns the action
 * @param {HTMLElement} rootElement - The root component element (for state collection)
 * @param {Object} options
 */
export async function sendAction(action, componentElement, rootElement,
                                 { apiPrefix = '', tokenExpired = null } = {}) {
  const payload = {
    action,
    state: collectStates(rootElement),
    // The component name travels alongside the id: the server splits the id into
    // "<name>-<path>" to find the component's place in the tree, and checks that
    // what sits there is what the browser thinks it is.
    component: componentElement.getAttribute('data-component') || undefined,
    'component-id': componentElement.getAttribute('data-component-id') || undefined,
    'render-token': _renderToken
  };

  try {
    // The page's query string travels with the action: the server rebuilds the root
    // component's props from the route definition plus the URL, so it needs the same
    // query parameters the page was rendered with.
    const response = await fetch(`${apiPrefix}/action${window.location.search}`, {
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

    if (response.status === 422) {
      const detail = await response.json().catch(() => ({}));
      const available = Array.isArray(detail.available) ? detail.available.join(', ') : '';
      console.error(
        `cl-s3r: action "${detail.action}" is not defined in component "${detail.component}"` +
        (available ? ` (available: ${available})` : ''));
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
 * The value a control contributes to a `change` action, appended as the action's
 * last argument the way submit appends its FormData.
 */
function controlValue(el) {
  if (!el) return null;
  if (el.tagName === 'SELECT') {
    return el.multiple
      ? Array.from(el.selectedOptions).map((o) => o.value)
      : el.value;
  }
  if (el.tagName === 'INPUT') {
    if (el.type === 'checkbox') return el.checked;
    if (el.type === 'file') return null;       // not serialisable; out of scope
    return el.value;                           // radio sends its value, text its text
  }
  return el.value !== undefined ? el.value : null;
}

/**
 * Find the component element that should handle the action named ACTION-NAME.
 * Walks up the component tree for the nearest ancestor that advertises the action
 * in its `data-actions` list, i.e. the component whose `let-function` defines it.
 * This is what lets a callback passed down as a prop reach the component that
 * owns it, even when it is rendered inside a child that has state of its own.
 * Falls back to the root element when no ancestor claims the action.
 */
function findActionTarget(element, actionName, mountContainer) {
  const wanted = String(actionName || '').toLowerCase();
  let el = element.closest('[data-component]');
  while (el && el !== mountContainer) {
    const actions = (el.getAttribute('data-actions') || '').split(/\s+/).filter(Boolean);
    if (actions.includes(wanted)) return el;
    const parent = el.parentElement;
    el = parent ? parent.closest('[data-component]') : null;
  }
  return mountContainer.firstElementChild;
}

/**
 * Initialize event delegation (click and submit handlers).
 * Actions are routed to the component that defines them (see findActionTarget).
 */
export function initRuntime(rootSelector = 'body', { apiPrefix = '', tokenExpired = null } = {}) {
  const mountContainer = document.querySelector(rootSelector);

  mountContainer.addEventListener('click', (event) => {
    const trigger = event.target.closest('[data-on-click]');
    if (!trigger) return;
    event.preventDefault();
    try {
      const action = JSON.parse(trigger.getAttribute('data-on-click'));
      const owningComp = findActionTarget(trigger, action[0], mountContainer);
      const root = mountContainer.firstElementChild;
      if (root) sendAction(action, owningComp, root, { apiPrefix, tokenExpired });
    } catch (e) {
      console.error('Failed to parse action JSON:', e);
    }
  });

  // `change` is the commit event for controls that are neither clicked nor
  // submitted: a <select>, a radio group, or a text field being left after an edit.
  mountContainer.addEventListener('change', (event) => {
    const trigger = event.target.closest('[data-on-change]');
    if (!trigger) return;
    try {
      const action = JSON.parse(trigger.getAttribute('data-on-change'));
      const owningComp = findActionTarget(trigger, action[0], mountContainer);
      // The value comes from the control that fired, which may sit below the
      // element carrying the handler.
      action.push(controlValue(event.target));
      const root = mountContainer.firstElementChild;
      if (root) sendAction(action, owningComp, root, { apiPrefix, tokenExpired });
    } catch (e) {
      console.error('Failed to parse change action JSON:', e);
    }
  });

  mountContainer.addEventListener('submit', (event) => {
    const form = event.target.closest('[data-on-submit]');
    if (!form) return;
    event.preventDefault();
    try {
      const action = JSON.parse(form.getAttribute('data-on-submit'));
      const formData = Object.fromEntries(new FormData(form).entries());
      const owningComp = findActionTarget(form, action[0], mountContainer);
      action.push(formData);
      const root = mountContainer.firstElementChild;
      if (root) sendAction(action, owningComp, root, { apiPrefix, tokenExpired });
      form.reset();
    } catch (e) {
      console.error('Failed to parse submit action JSON:', e);
    }
  });
}
