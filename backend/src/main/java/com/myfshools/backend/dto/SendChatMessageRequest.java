package com.myfshools.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record SendChatMessageRequest(
        @NotBlank String text
) {
}
