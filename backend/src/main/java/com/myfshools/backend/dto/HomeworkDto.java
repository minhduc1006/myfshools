package com.myfshools.backend.dto;

public record HomeworkDto(
        Long id,
        String title,
        String subject,
        String due,
        String status,
        String progress
) {
}
