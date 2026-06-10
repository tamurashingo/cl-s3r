/**
 * cl-morph - Lightweight DOM morphing utility
 *
 * Updates a live DOM element in-place to match a detached reference element,
 * touching only what changed (attributes, text, children).
 * The root node reference is preserved so event listeners and DevTools
 * selections remain stable across updates.
 */

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
}

function morphNode(oldNode, newNode) {
  if (oldNode.nodeType !== newNode.nodeType) {
    oldNode.parentNode.replaceChild(newNode.cloneNode(true), oldNode);
    return;
  }

  if (oldNode.nodeType === Node.TEXT_NODE || oldNode.nodeType === Node.COMMENT_NODE) {
    if (oldNode.nodeValue !== newNode.nodeValue) {
      oldNode.nodeValue = newNode.nodeValue;
    }
    return;
  }

  if (oldNode.nodeType === Node.ELEMENT_NODE) {
    if (oldNode.tagName !== newNode.tagName) {
      oldNode.parentNode.replaceChild(newNode.cloneNode(true), oldNode);
      return;
    }
    syncAttributes(oldNode, newNode);
    morphChildren(oldNode, newNode);
  }
}

function morphChildren(oldParent, newParent) {
  const oldChildren = Array.from(oldParent.childNodes);
  const newChildren = Array.from(newParent.childNodes);
  const minLen = Math.min(oldChildren.length, newChildren.length);

  for (let i = 0; i < minLen; i++) {
    morphNode(oldChildren[i], newChildren[i]);
  }

  for (let i = oldChildren.length; i < newChildren.length; i++) {
    oldParent.appendChild(newChildren[i].cloneNode(true));
  }

  for (let i = oldChildren.length - 1; i >= newChildren.length; i--) {
    oldParent.removeChild(oldChildren[i]);
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
