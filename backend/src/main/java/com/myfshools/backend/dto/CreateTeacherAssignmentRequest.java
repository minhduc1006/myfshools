package com.myfshools.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateTeacherAssignmentRequest(
        @NotBlank String title,
        @NotBlank String subject,
        @NotBlank String targetClass,
        @NotBlank String dueDate,
        String note,
        String attachmentName
) {
}
