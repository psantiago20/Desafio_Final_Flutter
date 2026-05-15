package com.pitaya.shared.util;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.Date;

public final class DateUtils {

    private static final String DEFAULT_PATTERN = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    private static final DateTimeFormatter DEFAULT_FORMATTER = DateTimeFormatter.ofPattern(DEFAULT_PATTERN);

    private DateUtils() {
        throw new UnsupportedOperationException("Utility class cannot be instantiated");
    }

    public static String format(Instant instant) {
        return format(instant, DEFAULT_FORMATTER);
    }

    public static String format(Instant instant, DateTimeFormatter formatter) {
        if (instant == null) return null;
        ZonedDateTime zdt = instant.atZone(ZoneId.of("UTC"));
        return formatter.format(zdt);
    }

    public static Instant parse(String dateString) {
        return parse(dateString, DEFAULT_FORMATTER);
    }

    public static Instant parse(String dateString, DateTimeFormatter formatter) {
        if (dateString == null || dateString.isBlank()) return null;
        LocalDateTime ldt = LocalDateTime.parse(dateString, formatter);
        return ldt.toInstant(java.time.ZoneOffset.UTC);
    }

    public static Instant now() {
        return Instant.now();
    }

    public static long toEpochMilli(Instant instant) {
        return instant != null ? instant.toEpochMilli() : 0L;
    }

    public static Instant fromEpochMilli(long epochMilli) {
        return Instant.ofEpochMilli(epochMilli);
    }

    public static LocalDate toLocalDate(Instant instant) {
        return instant != null
                ? instant.atZone(ZoneId.of("UTC")).toLocalDate()
                : null;
    }

    public static Date toDate(Instant instant) {
        return instant != null ? Date.from(instant) : null;
    }

    public static Instant fromDate(Date date) {
        return date != null ? date.toInstant() : null;
    }

    public static long daysBetween(Instant start, Instant end) {
        return ChronoUnit.DAYS.between(start, end);
    }

    public static long hoursBetween(Instant start, Instant end) {
        return ChronoUnit.HOURS.between(start, end);
    }

    public static Instant addDays(Instant instant, long days) {
        return instant != null ? instant.plus(days, ChronoUnit.DAYS) : null;
    }

    public static Instant addHours(Instant instant, long hours) {
        return instant != null ? instant.plus(hours, ChronoUnit.HOURS) : null;
    }

    public static boolean isAfter(Instant instant, Instant reference) {
        return instant != null && reference != null && instant.isAfter(reference);
    }

    public static boolean isBefore(Instant instant, Instant reference) {
        return instant != null && reference != null && instant.isBefore(reference);
    }
}
