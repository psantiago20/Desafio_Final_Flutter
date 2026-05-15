export function useInfiniteScroll(callback, options = {}) {
  const { threshold = 200, rootMargin = '0px', enabled = true } = options;
  let sentinel = null;
  let observer = null;
  let loading = false;

  function createSentinel() {
    const el = document.createElement('div');
    el.className = 'infinite-scroll-trigger';
    return el;
  }

  function init(container) {
    if (!container || !enabled) return;
    sentinel = createSentinel();
    container.appendChild(sentinel);

    observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && !loading && enabled) {
          loading = true;
          const result = callback();
          if (result && typeof result.finally === 'function') {
            result.finally(() => { loading = false; });
          } else {
            loading = false;
          }
        }
      },
      { rootMargin, threshold: 0 }
    );
    observer.observe(sentinel);
  }

  function setLoading(l) {
    loading = l;
  }

  function destroy() {
    if (observer) {
      observer.disconnect();
      observer = null;
    }
    if (sentinel && sentinel.parentNode) {
      sentinel.parentNode.removeChild(sentinel);
    }
    sentinel = null;
  }

  function refresh() {
    if (observer && sentinel) {
      observer.unobserve(sentinel);
      observer.observe(sentinel);
    }
  }

  return { init, destroy, setLoading, refresh };
}

export default useInfiniteScroll;
