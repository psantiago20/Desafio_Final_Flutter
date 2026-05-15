package com.pitaya.user.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

import java.util.regex.Pattern;

public class LattesUrlValidator implements ConstraintValidator<ValidLattesUrl, String> {

    private static final Pattern LATTES_PATTERN =
        Pattern.compile("^https?://lattes\\.cnpq\\.br/\\d+.*$");

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if (value == null || value.isBlank()) {
            return true;
        }
        return LATTES_PATTERN.matcher(value).matches();
    }
}
