/**
 * cl-morph - Lightweight DOM morphing utility
 *
 * Updates a live DOM element in-place to match a detached reference element,
 * touching only what changed (attributes, text, children).
 *
 * Children are matched by key where one is available, so an element keeps its
 * identity -- and with it the focus, scroll position, typed-in value, open
 * <details> and running CSS transition it carries -- when siblings around it are
 * inserted, removed or re-ordered. Keys come from `data-component-id` (assigned
 * by the framework to every component root) or from `data-key` (written as
 * `(@ (key ...))` on a plain element). Unkeyed children are matched by position,
 * as before.
 */

function nodeKey(node) {
  if (!node || node.nodeType !== Node.ELEMENT_NODE) return null;
  return node.getAttribute('data-component-id') || node.getAttribute('data-key') || null;
}

function syncAttributes(oldEl, newEl) {
  for (const attr of Array.from(oldEl.attributes)) {
    if (!newEl.hasAttribute(attr.name)) {
      oldEl.removeAttribute(attr.name);
    }
  }
  for (const attr of Array.from(newEl.attributes)) {
    if (oldEl.getAttribute(attr.name) !== attr.value) {
      oldEl.setAttribute(attr.name, attr.value);
    }
  }
  // `checked` is a property, not an attribute: a checkbox driven by the server
  // needs it pushed explicitly. `value` is deliberately left alone -- text
  // inputs are uncontrolled, so what the user has typed is not overwritten.
  if ('checked' in oldEl && 'checked' in newEl && oldEl.checked !== newEl.checked) {
    oldEl.checked = newEl.checked;
  }
}

/**
 * Push a <select>'s selection from the server's markup.
 * Selectedness is a property, and once the user has picked an option the
 * `selected` attribute no longer drives it -- so a server-controlled select needs
 * this, for the same reason a checkbox needs `checked`. Called after the options
 * have been morphed, so they exist to select.
 */
function syncSelect(oldEl, newEl) {
  if (oldEl.multiple) {
    const wanted = new Set(Array.from(newEl.selectedOptions).map((o) => o.value));
    for (const option of oldEl.options) {
      const selected = wanted.has(option.value);
      if (option.selected !== selected) option.selected = selected;
    }
  } else if (oldEl.value !== newEl.value) {
    oldEl.value = newEl.value;
  }
}

/**
 * Morph OLDNODE to match NEWNODE, returning the live node that ended up in the
 * DOM -- OLDNODE itself when it could be reused, or its replacement when the
 * node type or tag differs.
 */
function morphNode(oldNode, newNode) {
  if (oldNode.nodeType !== newNode.nodeType) {
    const replacement = newNode.cloneNode(true);
    oldNode.parentNode.replaceChild(replacement, oldNode);
    return replacement;
  }

  if (oldNode.nodeType === Node.TEXT_NODE || oldNode.nodeType === Node.COMMENT_NODE) {
    if (oldNode.nodeValue !== newNode.nodeValue) {
      oldNode.nodeValue = newNode.nodeValue;
    }
    return oldNode;
  }

  if (oldNode.nodeType === Node.ELEMENT_NODE) {
    if (oldNode.tagName !== newNode.tagName) {
      const replacement = newNode.cloneNode(true);
      oldNode.parentNode.replaceChild(replacement, oldNode);
      return replacement;
    }
    syncAttributes(oldNode, newNode);
    morphChildren(oldNode, newNode);
    if (oldNode.tagName === 'SELECT') {
      syncSelect(oldNode, newNode);
    }
  }
  return oldNode;
}

function morphChildren(oldParent, newParent) {
  const newChildren = Array.from(newParent.childNodes);
  const oldChildren = Array.from(oldParent.childNodes);

  // Old children that carry a key, addressable wherever they sit now.
  const keyed = new Map();
  for (const node of oldChildren) {
    const key = nodeKey(node);
    if (key !== null && !keyed.has(key)) keyed.set(key, node);
  }
  // The rest keep being matched in order.
  const unkeyed = oldChildren.filter((node) => nodeKey(node) === null);

  // Decide which live node (if any) serves each new child, before touching the DOM.
  let nextUnkeyed = 0;
  const plan = newChildren.map((newChild) => {
    const key = nodeKey(newChild);
    if (key !== null) {
      const match = keyed.get(key);
      if (match) keyed.delete(key);
      return match || null;
    }
    return nextUnkeyed < unkeyed.length ? unkeyed[nextUnkeyed++] : null;
  });

  // Walk the live list in the order the new children require, moving reused
  // nodes into place and inserting fresh ones where nothing was reused.
  let cursor = oldParent.firstChild;
  for (let i = 0; i < newChildren.length; i++) {
    let node = plan[i]
      ? morphNode(plan[i], newChildren[i])
      : newChildren[i].cloneNode(true);

    if (node === cursor) {
      cursor = cursor.nextSibling;
    } else {
      oldParent.insertBefore(node, cursor);
    }
  }

  // Anything still after the cursor was not claimed by a new child.
  while (cursor) {
    const next = cursor.nextSibling;
    oldParent.removeChild(cursor);
    cursor = next;
  }
}

/**
 * Morph the live element `oldEl` to match `newEl`.
 * `oldEl` stays in place in the DOM; only deltas are applied.
 *
 * @param {Element} oldEl - The live root element to update
 * @param {Element} newEl - The parsed server-response element (detached)
 */
export function morphElement(oldEl, newEl) {
  if (oldEl.tagName !== newEl.tagName) {
    if (oldEl.parentNode) {
      oldEl.parentNode.replaceChild(newEl.cloneNode(true), oldEl);
    }
    return;
  }

  syncAttributes(oldEl, newEl);
  morphChildren(oldEl, newEl);
}
