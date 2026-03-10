package com.myfshools.backend.dto;

public record PayOsCheckoutDto(
        Long invoiceId,
        Long orderCode,
        String checkoutUrl,
        String qrCode,
        String status
) {
}
