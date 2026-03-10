package com.myfshools.backend.dto;

public record TeacherAssignmentDto(
        Long id,
        String title,
        String subject,
        String targetClass,
        String dueDate,
        String note,
        String attachmentName,
        String createdAt,
        String createdBy
) {
}
