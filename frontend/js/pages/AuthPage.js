import Component from '../components/Component.js';
import { login, register } from '../services/auth.service.js';
import authStore from '../state/auth.store.js';
import { validateEmail, validatePassword, validateUsername, validateRequired, validateMatch, validateMaxLength } from '../utils/validation.js';
import { MAX_USERNAME_LENGTH } from '../constants/config.js';

export default class AuthPage extends Component {
  constructor(options = {}) {
    super(options);
    this.state = {
      tab: 'login',
      loginEmail: '',
      loginPassword: '',
      regName: '',
      regUsername: '',
      regEmail: '',
      regPassword: '',
      regConfirmPassword: '',
      regBirthDate: '',
      regRole: 'USER',
      errors: {},
      isSubmitting: false,
    };
  }

  template() {
    const isLogin = this.state.tab === 'login';
    const { errors, isSubmitting } = this.state;
    const authError = authStore.get('error');

    return `
      <div class="auth-page">
        <div class="auth-card">
          <div class="auth-header">
            <div class="auth-logo">Pitaya</div>
            <p class="auth-subtitle">Rede Social Acadêmica</p>
          </div>

          <div class="auth-tabs">
            <div class="auth-tab ${isLogin ? 'active' : ''}" data-tab="login">Entrar</div>
            <div class="auth-tab ${!isLogin ? 'active' : ''}" data-tab="register">Cadastrar</div>
          </div>

          ${authError ? `<div class="auth-error visible">${authError}</div>` : '<div class="auth-error"></div>'}

          ${isLogin ? this._loginForm() : this._registerForm()}
        </div>
      </div>
    `;
  }

  _loginForm() {
    return `
      <form class="auth-form" data-login-form>
        <div class="form-group">
          <label>Email</label>
          <input type="email" name="loginEmail" placeholder="seu@email.com" value="${this.state.loginEmail}" data-login-email />
          ${this.state.errors.loginEmail ? `<div class="form-error">${this.state.errors.loginEmail}</div>` : ''}
        </div>
        <div class="form-group">
          <label>Senha</label>
          <input type="password" name="loginPassword" placeholder="Sua senha" value="" data-login-password />
          ${this.state.errors.loginPassword ? `<div class="form-error">${this.state.errors.loginPassword}</div>` : ''}
        </div>
        <button class="btn btn-primary btn-lg" type="submit" ${isSubmitting ? 'disabled' : ''}>
          ${isSubmitting ? 'Entrando...' : 'Entrar'}
        </button>
        <div class="form-footer mt-md">
          <a href="#/login" data-forgot>Esqueceu a senha?</a>
        </div>
      </form>
    `;
  }

  _registerForm() {
    return `
      <form class="auth-form" data-register-form>
        <div class="form-group">
          <label>Nome completo</label>
          <input type="text" placeholder="Seu nome" value="${this.state.regName}" data-reg-name />
          ${this.state.errors.regName ? `<div class="form-error">${this.state.errors.regName}</div>` : ''}
        </div>
        <div class="form-group">
          <label>Nome de usuário</label>
          <input type="text" placeholder="username" value="${this.state.regUsername}" data-reg-username />
          ${this.state.errors.regUsername ? `<div class="form-error">${this.state.errors.regUsername}</div>` : ''}
        </div>
        <div class="form-group">
          <label>Email</label>
          <input type="email" placeholder="seu@email.com" value="${this.state.regEmail}" data-reg-email />
          ${this.state.errors.regEmail ? `<div class="form-error">${this.state.errors.regEmail}</div>` : ''}
        </div>
        <div class="form-group">
          <label>Senha</label>
          <input type="password" placeholder="Mínimo 8 caracteres" value="" data-reg-password />
          ${this.state.errors.regPassword ? `<div class="form-error">${this.state.errors.regPassword}</div>` : ''}
        </div>
        <div class="form-group">
          <label>Confirmar senha</label>
          <input type="password" placeholder="Repita a senha" value="" data-reg-confirm />
          ${this.state.errors.regConfirmPassword ? `<div class="form-error">${this.state.errors.regConfirmPassword}</div>` : ''}
        </div>
        <div class="form-group">
          <label>Data de nascimento</label>
          <input type="date" value="${this.state.regBirthDate}" data-reg-birth />
        </div>
        <div class="form-group">
          <label>Tipo de conta</label>
          <select data-reg-role>
            <option value="USER" ${this.state.regRole === 'USER' ? 'selected' : ''}>Estudante</option>
            <option value="ADMIN" ${this.state.regRole === 'ADMIN' ? 'selected' : ''}>Professor/Pesquisador</option>
          </select>
        </div>
        <button class="btn btn-primary btn-lg" type="submit" ${isSubmitting ? 'disabled' : ''}>
          ${isSubmitting ? 'Cadastrando...' : 'Criar conta'}
        </button>
      </form>
    `;
  }

  events() {
    return {
      'click [data-tab]': '_switchTab',
      'submit [data-login-form]': '_handleLogin',
      'submit [data-register-form]': '_handleRegister',
      'input [data-login-email]': '_updateField',
      'input [data-login-password]': '_updateField',
      'input [data-reg-name]': '_updateField',
      'input [data-reg-username]': '_updateField',
      'input [data-reg-email]': '_updateField',
      'input [data-reg-password]': '_updateField',
      'input [data-reg-confirm]': '_updateField',
      'input [data-reg-birth]': '_updateField',
      'change [data-reg-role]': '_updateField',
    };
  }

  _updateField(e) {
    const el = e.target;
    const key = el.dataset[Object.keys(el.dataset)[0]];
    const fieldMap = {
      loginEmail: 'loginEmail',
      loginPassword: 'loginPassword',
      regName: 'regName',
      regUsername: 'regUsername',
      regEmail: 'regEmail',
      regPassword: 'regPassword',
      regConfirm: 'regConfirmPassword',
      regBirth: 'regBirthDate',
      regRole: 'regRole',
    };
    const inputName = el.name || Object.keys(el.dataset)[0];
    const mappedKey = Object.keys(el.dataset).reduce((acc, d) => {
      const m = { loginEmail: 'loginEmail', loginPassword: 'loginPassword', regName: 'regName', regUsername: 'regUsername', regEmail: 'regEmail', regPassword: 'regPassword', regConfirm: 'regConfirmPassword', regBirth: 'regBirthDate', regRole: 'regRole' };
      return m[el.dataset[d]] || acc;
    }, null);
    const stateKey = fieldMap[Object.keys(el.dataset)[0]] || Object.keys(el.dataset)[0];
    this.state[stateKey] = el.value;
  }

  _switchTab(e) {
    const tab = e.currentTarget.dataset.tab;
    if (tab) {
      this.state.tab = tab;
      this.state.errors = {};
      authStore.set({ error: null });
      this.render();
    }
  }

  async _handleLogin(e) {
    e.preventDefault();
    const errors = {};
    const emailVal = validateEmail(this.state.loginEmail);
    if (!emailVal.valid) errors.loginEmail = emailVal.error;
    const passVal = validatePassword(this.state.loginPassword);
    if (!passVal.valid) errors.loginPassword = passVal.error;

    if (Object.keys(errors).length) {
      this.state.errors = errors;
      this.render();
      return;
    }

    this.state.isSubmitting = true;
    this.state.errors = {};
    this.render();

    try {
      await login(this.state.loginEmail, this.state.loginPassword);
      window.location.hash = '#/feed';
    } catch {
      this.state.isSubmitting = false;
      this.render();
    }
  }

  async _handleRegister(e) {
    e.preventDefault();
    const errors = {};
    const nameVal = validateRequired(this.state.regName, 'Nome');
    if (!nameVal.valid) errors.regName = nameVal.error;
    const userVal = validateUsername(this.state.regUsername);
    if (!userVal.valid) errors.regUsername = userVal.error;
    const emailVal = validateEmail(this.state.regEmail);
    if (!emailVal.valid) errors.regEmail = emailVal.error;
    const passVal = validatePassword(this.state.regPassword);
    if (!passVal.valid) errors.regPassword = passVal.error;
    const matchVal = validateMatch(this.state.regPassword, this.state.regConfirmPassword, 'Senhas');
    if (!matchVal.valid) errors.regConfirmPassword = matchVal.error;

    if (Object.keys(errors).length) {
      this.state.errors = errors;
      this.render();
      return;
    }

    this.state.isSubmitting = true;
    this.state.errors = {};
    this.render();

    try {
      await register(this.state.regName, this.state.regUsername, this.state.regEmail, this.state.regPassword);
      window.location.hash = '#/feed';
    } catch {
      this.state.isSubmitting = false;
      this.render();
    }
  }

  destroy() {
    authStore.set({ error: null });
    super.destroy();
  }
}
