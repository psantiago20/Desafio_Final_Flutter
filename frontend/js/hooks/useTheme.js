import { getTheme, setTheme, toggleTheme, initTheme } from '../services/theme.service.js';

export function useTheme() {
  return {
    get theme() { return getTheme(); },
    setTheme,
    toggleTheme,
    initTheme,
  };
}

export default useTheme;
