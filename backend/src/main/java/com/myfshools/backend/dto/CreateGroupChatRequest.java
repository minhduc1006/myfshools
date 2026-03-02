package com.myfshools.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.List;

public record CreateGroupChatRequest(
        @NotBlank String name,
        @Size(max = 100) List<String> memberPhones
) {
}
