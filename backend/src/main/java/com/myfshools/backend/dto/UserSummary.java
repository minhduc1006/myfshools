package com.myfshools.backend.dto;

import java.math.BigDecimal;

public record UserSummary(
        Long id,
        String phone,
        String fullName,
        String className,
        String role,
        String managedClass,
        String subjectSpecialty,
        String term,
        BigDecimal gpa,
        String avatarInitial
) {
}
