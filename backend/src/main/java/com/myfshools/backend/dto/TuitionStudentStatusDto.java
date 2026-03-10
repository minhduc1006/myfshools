package com.myfshools.backend.dto;

public record TuitionStudentStatusDto(
        Long studentId,
        String studentPhone,
        String studentName,
        String className,
        String status,
        int totalAmount,
        int paidAmount
) {
}

