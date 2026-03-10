package com.myfshools.backend.dto;

public record HomeworkStudentStatusDto(
        String studentPhone,
        String studentName,
        String className,
        String title,
        String subject,
        String dueDate,
        String status
) {
}
