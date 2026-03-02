package com.myfshools.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record AuthLoginRequest(
        @NotBlank String phone,
        @NotBlank String password
) {
}
