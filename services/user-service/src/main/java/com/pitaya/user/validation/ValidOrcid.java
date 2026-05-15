package com.pitaya.user.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Constraint(validatedBy = OrcidValidator.class)
public @interface ValidOrcid {

    String message() default "Invalid ORCID format. Expected format: 0000-0000-0000-0000";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
