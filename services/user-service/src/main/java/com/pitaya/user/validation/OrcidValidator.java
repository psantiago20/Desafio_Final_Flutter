package com.pitaya.user.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

import java.util.regex.Pattern;

public class OrcidValidator implements ConstraintValidator<ValidOrcid, String> {

    private static final Pattern ORCID_PATTERN =
        Pattern.compile("^\\d{4}-\\d{4}-\\d{4}-\\d{3}[\\dX]$");

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if (value == null || value.isBlank()) {
            return true;
        }
        return ORCID_PATTERN.matcher(value).matches();
    }
}
