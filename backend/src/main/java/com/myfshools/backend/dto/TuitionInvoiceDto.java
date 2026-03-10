package com.myfshools.backend.dto;

public record TuitionInvoiceDto(
        Long id,
        String title,
        Integer amount,
        String availableFrom,
        String dueDate,
        String status,
        Long payOsOrderCode,
        String checkoutUrl,
        String qrCode,
        String paidAt
) {
}
