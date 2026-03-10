package com.myfshools.backend.dto;

public record HomeworkClassReportDto(
        String className,
        int totalStudents,
        int submittedCount,
        int pendingCount,
        int overdueCount
) {
}
