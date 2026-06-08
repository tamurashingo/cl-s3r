/**
 * cl-runtime - State collection and server communication runtime
 */

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
      component: element.tagName.toLowerCase(),
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
 */
export async function sendAction(action, rootElement, { apiPrefix = '' } = {}) {
  const state = collectStates(rootElement);
  const payload = {
    action, // Already in JSON array form: ["name", ...args]
    state
  };

  console.log('Sending payload:', payload);

  try {
    const response = await fetch(`${apiPrefix}/action`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    if (!response.ok) throw new Error('Network response was not ok');

    const result = await response.json();
    if (result.html) {
      // Replace the root component element with the new HTML
      const temp = document.createElement('div');
      temp.innerHTML = result.html;
      const newElement = temp.firstElementChild;

      if (newElement && rootElement.parentNode) {
        rootElement.parentNode.replaceChild(newElement, rootElement);
        // Ensure data-state is set on the new element
        if (result.state) {
          newElement.setAttribute('data-state', JSON.stringify(result.state));
        }
      } else {
        // Fallback
        rootElement.innerHTML = result.html;
        if (result.state) {
          rootElement.setAttribute('data-state', JSON.stringify(result.state));
        }
      }
    }
  } catch (error) {
    console.error('Failed to send action:', error);
  }
}

/**
 * Initialize event delegation (click and submit handlers).
 * All actions route to the root component (direct child of mount container).
 */
export function initRuntime(rootSelector = 'body', { apiPrefix = '' } = {}) {
  const mountContainer = document.querySelector(rootSelector);

  mountContainer.addEventListener('click', (event) => {
    const trigger = event.target.closest('[data-on-click]');
    if (!trigger) return;
    try {
      const action = JSON.parse(trigger.getAttribute('data-on-click'));
      const root = mountContainer.firstElementChild;
      if (root) sendAction(action, root, { apiPrefix });
    } catch (e) {
      console.error('Failed to parse action JSON:', e);
    }
  });

  mountContainer.addEventListener('submit', (event) => {
    event.preventDefault();
    const form = event.target.closest('[data-on-submit]');
    if (!form) return;
    try {
      const action = JSON.parse(form.getAttribute('data-on-submit'));
      const formData = Object.fromEntries(new FormData(form).entries());
      action.push(formData);
      const root = mountContainer.firstElementChild;
      if (root) sendAction(action, root, { apiPrefix });
      form.reset();
    } catch (e) {
      console.error('Failed to parse submit action JSON:', e);
    }
  });
}
