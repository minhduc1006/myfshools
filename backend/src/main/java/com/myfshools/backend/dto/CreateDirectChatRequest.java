package com.myfshools.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateDirectChatRequest(
        @NotBlank String phone
) {
}
