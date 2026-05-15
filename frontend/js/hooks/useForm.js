export function useForm(options = {}) {
  const { initialValues = {}, validationRules = {}, onSubmit } = options;

  let values = { ...initialValues };
  let errors = {};
  let touched = {};
  let submitting = false;

  function setValue(field, value) {
    values = { ...values, [field]: value };
    if (touched[field]) {
      validateField(field);
    }
  }

  function setValues(newValues) {
    values = { ...values, ...newValues };
  }

  function setTouched(field) {
    touched = { ...touched, [field]: true };
    validateField(field);
  }

  function validateField(field) {
    const rules = validationRules[field];
    if (!rules) return;
    for (const rule of rules) {
      const result = rule(values[field], values);
      if (!result.valid) {
        errors = { ...errors, [field]: result.error };
        return;
      }
    }
    const { [field]: _, ...rest } = errors;
    errors = rest;
  }

  function validateAll() {
    let valid = true;
    const newErrors = {};
    for (const field of Object.keys(validationRules)) {
      touched = { ...touched, [field]: true };
      const rules = validationRules[field];
      for (const rule of rules) {
        const result = rule(values[field], values);
        if (!result.valid) {
          newErrors[field] = result.error;
          valid = false;
          break;
        }
      }
    }
    errors = newErrors;
    return valid;
  }

  function getFieldProps(field) {
    return {
      value: values[field] || '',
      onChange: (e) => setValue(field, e.target.value),
      onBlur: () => setTouched(field),
      error: touched[field] ? errors[field] : null,
      name: field,
    };
  }

  function resetForm(newVals) {
    values = { ...(newVals || initialValues) };
    errors = {};
    touched = {};
    submitting = false;
  }

  function handleSubmit(e) {
    if (e) e.preventDefault();
    if (!validateAll()) return;
    submitting = true;
    const result = onSubmit?.(values);
    if (result && typeof result.finally === 'function') {
      return result.finally(() => { submitting = false; });
    }
    submitting = false;
    return result;
  }

  return {
    get values() { return values; },
    get errors() { return errors; },
    get touched() { return touched; },
    get submitting() { return submitting; },
    get valid() { return Object.keys(errors).length === 0; },
    setValue,
    setValues,
    setTouched,
    validateAll,
    getFieldProps,
    resetForm,
    handleSubmit,
  };
}

export default useForm;
