package com.myfshools.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateNoticeRequest(
        @NotBlank String title,
        @NotBlank String message,
        String target,
        String className
) {
}

