package com.myfshools.backend.dto;

public record TuitionClassSummaryDto(
        String className,
        int totalStudents,
        int paidStudents,
        int pendingStudents,
        int unpaidStudents,
        int totalAmount,
        int paidAmount
) {
}
