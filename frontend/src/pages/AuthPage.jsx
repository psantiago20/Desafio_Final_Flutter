import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useUI } from '../contexts/UIContext';
import { validateEmail, validatePassword, validateUsername, validateRequired, validateMatch } from '../utils/validation';
import { MAX_USERNAME_LENGTH } from '../constants/config';

export default function AuthPage() {
  const { login, register, error, setError } = useAuth();
  const { addSuccessToast } = useUI();
  const navigate = useNavigate();

  const [tab, setTab] = useState('login');
  const [form, setForm] = useState({
    loginEmail: '', loginPassword: '',
    regName: '', regUsername: '', regEmail: '', regPassword: '',
    regConfirmPassword: '', regBirthDate: '', regRole: 'USER',
  });
  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const updateField = (field) => (e) => {
    setForm(prev => ({ ...prev, [field]: e.target.value }));
    setErrors(prev => ({ ...prev, [field]: undefined }));
    setError(null);
  };

  const switchTab = (t) => {
    setTab(t);
    setErrors({});
    setError(null);
  };

  const handleLogin = async (e) => {
    e.preventDefault();
    const errs = {};
    const emailVal = validateEmail(form.loginEmail);
    if (!emailVal.valid) errs.loginEmail = emailVal.error;
    const passVal = validatePassword(form.loginPassword);
    if (!passVal.valid) errs.loginPassword = passVal.error;
    if (Object.keys(errs).length) { setErrors(errs); return; }

    setIsSubmitting(true);
    try {
      await login(form.loginEmail, form.loginPassword);
      navigate('/feed');
    } catch {
      setIsSubmitting(false);
    }
  };

  const handleRegister = async (e) => {
    e.preventDefault();
    const errs = {};
    const nameVal = validateRequired(form.regName, 'Nome');
    if (!nameVal.valid) errs.regName = nameVal.error;
    const userVal = validateUsername(form.regUsername);
    if (!userVal.valid) errs.regUsername = userVal.error;
    const emailVal = validateEmail(form.regEmail);
    if (!emailVal.valid) errs.regEmail = emailVal.error;
    const passVal = validatePassword(form.regPassword);
    if (!passVal.valid) errs.regPassword = passVal.error;
    const matchVal = validateMatch(form.regPassword, form.regConfirmPassword, 'Senhas');
    if (!matchVal.valid) errs.regConfirmPassword = matchVal.error;

    if (Object.keys(errs).length) { setErrors(errs); return; }

    setIsSubmitting(true);
    try {
      await register(form.regName, form.regUsername, form.regEmail, form.regPassword);
      navigate('/feed');
    } catch {
      setIsSubmitting(false);
    }
  };

  const isLogin = tab === 'login';

  return (
    <div className="auth-page">
      <div className="auth-card">
        <div className="auth-header">
          <div className="auth-logo">Pitaya</div>
          <p className="auth-subtitle">Rede Social Acadêmica</p>
        </div>

        <div className="auth-tabs">
          <div className={`auth-tab ${isLogin ? 'active' : ''}`} onClick={() => switchTab('login')}>Entrar</div>
          <div className={`auth-tab ${!isLogin ? 'active' : ''}`} onClick={() => switchTab('register')}>Cadastrar</div>
        </div>

        {error && <div className="auth-error visible">{error}</div>}

        {isLogin ? (
          <form className="auth-form" onSubmit={handleLogin}>
            <div className="form-group">
              <label>Email</label>
              <input type="email" placeholder="seu@email.com" value={form.loginEmail}
                onChange={updateField('loginEmail')} />
              {errors.loginEmail && <div className="form-error">{errors.loginEmail}</div>}
            </div>
            <div className="form-group">
              <label>Senha</label>
              <input type="password" placeholder="Sua senha" value={form.loginPassword}
                onChange={updateField('loginPassword')} />
              {errors.loginPassword && <div className="form-error">{errors.loginPassword}</div>}
            </div>
            <button className="btn btn-primary btn-lg" type="submit" disabled={isSubmitting}>
              {isSubmitting ? 'Entrando...' : 'Entrar'}
            </button>
            <div className="form-footer mt-md">
              <a href="/forgot-password">Esqueceu a senha?</a>
            </div>
          </form>
        ) : (
          <form className="auth-form" onSubmit={handleRegister}>
            <div className="form-group">
              <label>Nome completo</label>
              <input type="text" placeholder="Seu nome" value={form.regName}
                onChange={updateField('regName')} />
              {errors.regName && <div className="form-error">{errors.regName}</div>}
            </div>
            <div className="form-group">
              <label>Nome de usuário</label>
              <input type="text" placeholder="username" value={form.regUsername}
                onChange={updateField('regUsername')} />
              {errors.regUsername && <div className="form-error">{errors.regUsername}</div>}
            </div>
            <div className="form-group">
              <label>Email</label>
              <input type="email" placeholder="seu@email.com" value={form.regEmail}
                onChange={updateField('regEmail')} />
              {errors.regEmail && <div className="form-error">{errors.regEmail}</div>}
            </div>
            <div className="form-group">
              <label>Senha</label>
              <input type="password" placeholder="Mínimo 8 caracteres" value={form.regPassword}
                onChange={updateField('regPassword')} />
              {errors.regPassword && <div className="form-error">{errors.regPassword}</div>}
            </div>
            <div className="form-group">
              <label>Confirmar senha</label>
              <input type="password" placeholder="Repita a senha" value={form.regConfirmPassword}
                onChange={updateField('regConfirmPassword')} />
              {errors.regConfirmPassword && <div className="form-error">{errors.regConfirmPassword}</div>}
            </div>
            <div className="form-group">
              <label>Data de nascimento</label>
              <input type="date" value={form.regBirthDate}
                onChange={updateField('regBirthDate')} />
            </div>
            <div className="form-group">
              <label>Tipo de conta</label>
              <select value={form.regRole} onChange={updateField('regRole')}>
                <option value="USER">Estudante</option>
                <option value="ADMIN">Professor/Pesquisador</option>
              </select>
            </div>
            <button className="btn btn-primary btn-lg" type="submit" disabled={isSubmitting}>
              {isSubmitting ? 'Cadastrando...' : 'Criar conta'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
