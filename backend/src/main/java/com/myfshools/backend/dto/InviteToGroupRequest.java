package com.myfshools.backend.dto;

import jakarta.validation.constraints.NotBlank;

public record InviteToGroupRequest(
        @NotBlank String phone
) {
}
