package com.myfshools.backend.dto;

public record AlertDto(
        Long id,
        String title,
        String message,
        String type,
        String createdAt,
        boolean read
) {
}
