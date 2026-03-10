package com.myfshools.backend.dto;

public record ServiceRequestDto(
        Long id,
        String title,
        String type,
        String category,
        String description,
        String status,
        String handlerNote,
        String requester,
        String createdAt,
        String updatedAt
) {
}
