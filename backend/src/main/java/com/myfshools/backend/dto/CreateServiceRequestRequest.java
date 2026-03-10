package com.myfshools.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateServiceRequestRequest(
        @NotBlank String title,
        @NotBlank String type,
        @NotBlank String category,
        @NotBlank String description
) {
}
