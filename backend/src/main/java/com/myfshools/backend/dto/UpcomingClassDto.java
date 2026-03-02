package com.myfshools.backend.dto;

public record UpcomingClassDto(
        Long id,
        String dayLabel,
        int dayNumber,
        String subject,
        String room,
        String startTime,
        String teacher
) {
}
