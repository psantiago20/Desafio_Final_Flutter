export function createElement(tag, options = {}) {
  const el = document.createElement(tag);
  if (options.className) el.className = options.className;
  if (options.id) el.id = options.id;
  if (options.text) el.textContent = options.text;
  if (options.html) el.innerHTML = options.html;
  if (options.attrs) {
    for (const [key, value] of Object.entries(options.attrs)) {
      el.setAttribute(key, value);
    }
  }
  if (options.dataset) {
    for (const [key, value] of Object.entries(options.dataset)) {
      el.dataset[key] = value;
    }
  }
  if (options.events) {
    for (const [event, handler] of Object.entries(options.events)) {
      el.addEventListener(event, handler);
    }
  }
  if (options.children) {
    for (const child of options.children) {
      if (typeof child === 'string') {
        el.appendChild(document.createTextNode(child));
      } else if (child instanceof Node) {
        el.appendChild(child);
      }
    }
  }
  return el;
}

export function qs(selector, context = document) {
  return context.querySelector(selector);
}

export function qsa(selector, context = document) {
  return context.querySelectorAll(selector);
}

export function delegate(parent, selector, eventType, handler) {
  parent.addEventListener(eventType, (e) => {
    const target = e.target.closest(selector);
    if (target && parent.contains(target)) {
      handler.call(target, e, target);
    }
  });
}

export function insertAfter(newNode, referenceNode) {
  referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
}

export function removeChildren(node) {
  while (node.firstChild) {
    node.removeChild(node.firstChild);
  }
}

export function empty(element) {
  removeChildren(element);
}

export function show(element) {
  element.style.display = '';
}

export function hide(element) {
  element.style.display = 'none';
}

export function toggle(element) {
  if (element.style.display === 'none') {
    show(element);
  } else {
    hide(element);
  }
}

export function hasClass(element, className) {
  return element.classList.contains(className);
}

export function addClass(element, className) {
  element.classList.add(className);
}

export function removeClass(element, className) {
  element.classList.remove(className);
}

export function toggleClass(element, className) {
  element.classList.toggle(className);
}

export function setAttributes(element, attrs) {
  for (const [key, value] of Object.entries(attrs)) {
    element.setAttribute(key, value);
  }
}

export function closest(element, selector) {
  return element.closest(selector);
}

export function getData(element, key) {
  return element.dataset[key];
}

export function setData(element, key, value) {
  element.dataset[key] = value;
}
