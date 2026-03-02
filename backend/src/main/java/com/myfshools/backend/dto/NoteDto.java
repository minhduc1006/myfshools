package com.myfshools.backend.dto;

public record NoteDto(
        Long id,
        String title,
        String preview,
        String content,
        String date
) {
}
