package com.myfshools.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateNoteRequest(
        @NotBlank String title,
        @NotBlank String content
) {
}
