package com.myfshools.backend.dto;

public record AuthLoginResponse(
        String accessToken,
        String tokenType,
        long expiresIn,
        UserSummary user
) {
}
