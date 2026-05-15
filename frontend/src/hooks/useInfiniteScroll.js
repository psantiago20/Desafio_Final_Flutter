import { useEffect, useRef, useCallback } from 'react';

export default function useInfiniteScroll(callback, options = {}) {
  const { enabled = true, rootMargin = '200px' } = options;
  const sentinelRef = useRef(null);
  const callbackRef = useRef(callback);
  const loadingRef = useRef(false);
  callbackRef.current = callback;

  useEffect(() => {
    if (!enabled || !sentinelRef.current) return;
    const sentinel = sentinelRef.current;

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && !loadingRef.current && enabled) {
          loadingRef.current = true;
          const result = callbackRef.current();
          if (result && typeof result.finally === 'function') {
            result.finally(() => { loadingRef.current = false; });
          } else {
            loadingRef.current = false;
          }
        }
      },
      { rootMargin, threshold: 0 }
    );

    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [enabled, rootMargin]);

  const setLoading = useCallback((l) => { loadingRef.current = l; }, []);

  return { sentinelRef, setLoading };
}
