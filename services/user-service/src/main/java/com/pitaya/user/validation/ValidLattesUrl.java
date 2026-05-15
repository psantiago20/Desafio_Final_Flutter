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
@Constraint(validatedBy = LattesUrlValidator.class)
public @interface ValidLattesUrl {

    String message() default "Invalid Lattes URL format. Must start with http://lattes.cnpq.br/";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
