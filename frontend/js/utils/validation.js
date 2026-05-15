export function validateEmail(email) {
  if (!email || email.trim().length === 0) return { valid: false, error: 'Email é obrigatório' };
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!re.test(email.trim())) return { valid: false, error: 'Email inválido' };
  return { valid: true, error: null };
}

export function validatePassword(password) {
  if (!password) return { valid: false, error: 'Senha é obrigatória' };
  if (password.length < 8) return { valid: false, error: 'Senha deve ter no mínimo 8 caracteres' };
  if (password.length > 128) return { valid: false, error: 'Senha deve ter no máximo 128 caracteres' };
  return { valid: true, error: null, strength: getPasswordStrength(password) };
}

export function getPasswordStrength(password) {
  let score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (/[a-z]/.test(password) && /[A-Z]/.test(password)) score++;
  if (/\d/.test(password)) score++;
  if (/[^a-zA-Z0-9]/.test(password)) score++;
  if (score <= 1) return 'fraca';
  if (score <= 2) return 'media';
  if (score <= 4) return 'forte';
  return 'muito-forte';
}

export function validateUsername(username) {
  if (!username || username.trim().length === 0) return { valid: false, error: 'Nome de usuário é obrigatório' };
  if (username.length < 3) return { valid: false, error: 'Nome de usuário deve ter no mínimo 3 caracteres' };
  if (username.length > 30) return { valid: false, error: 'Nome de usuário deve ter no máximo 30 caracteres' };
  if (!/^[a-zA-Z0-9_]+$/.test(username)) return { valid: false, error: 'Nome de usuário deve conter apenas letras, números e underscore' };
  return { valid: true, error: null };
}

export function validateRequired(value, fieldName = 'Campo') {
  if (!value || (typeof value === 'string' && value.trim().length === 0)) {
    return { valid: false, error: `${fieldName} é obrigatório` };
  }
  return { valid: true, error: null };
}

export function validateUrl(url) {
  if (!url || url.trim().length === 0) return { valid: true, error: null };
  try {
    new URL(url.trim());
    return { valid: true, error: null };
  } catch {
    return { valid: false, error: 'URL inválida' };
  }
}

export function validateMaxLength(value, maxLength, fieldName = 'Campo') {
  if (value && value.length > maxLength) {
    return { valid: false, error: `${fieldName} deve ter no máximo ${maxLength} caracteres` };
  }
  return { valid: true, error: null };
}

export function validateMatch(value1, value2, fieldName = 'Campos') {
  if (value1 !== value2) {
    return { valid: false, error: `${fieldName} não conferem` };
  }
  return { valid: true, error: null };
}

export function validateForm(rules) {
  const errors = {};
  let isValid = true;
  for (const [field, validators] of Object.entries(rules)) {
    for (const validator of validators) {
      const result = validator();
      if (!result.valid) {
        errors[field] = result.error;
        isValid = false;
        break;
      }
    }
  }
  return { isValid, errors };
}
