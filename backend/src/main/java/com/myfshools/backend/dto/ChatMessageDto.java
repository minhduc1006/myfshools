package com.myfshools.backend.dto;

public record ChatMessageDto(
        Long id,
        boolean fromMe,
        String text,
        String time
) {
}
