export function validateEmail(email) {
  if (!email) return { valid: false, error: 'Email é obrigatório' };
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!re.test(email)) return { valid: false, error: 'Email inválido' };
  return { valid: true };
}

export function validatePassword(password) {
  if (!password) return { valid: false, error: 'Senha é obrigatória' };
  if (password.length < 8) return { valid: false, error: 'Mínimo 8 caracteres' };
  return { valid: true };
}

export function validateUsername(username) {
  if (!username) return { valid: false, error: 'Usuário é obrigatório' };
  if (username.length < 3) return { valid: false, error: 'Mínimo 3 caracteres' };
  if (!/^[a-zA-Z0-9_]+$/.test(username)) return { valid: false, error: 'Apenas letras, números e _' };
  return { valid: true };
}

export function validateRequired(value, field) {
  if (!value || !value.trim()) return { valid: false, error: `${field} é obrigatório` };
  return { valid: true };
}

export function validateMatch(a, b, field) {
  if (a !== b) return { valid: false, error: `${field} não conferem` };
  return { valid: true };
}

export function validateMaxLength(value, max, field) {
  if (value && value.length > max) return { valid: false, error: `${field} deve ter no máximo ${max} caracteres` };
  return { valid: true };
}
