package com.myfshools.backend.dto;

public record ScheduleItemDto(
        Long id,
        int dayOfWeekIndex,
        String dayShort,
        String dayFull,
        int dayOfMonth,
        String scheduleDate,
        int weekOfSemester,
        String subject,
        String room,
        String startTime,
        String endTime,
        String teacher,
        String colorHex
) {
}
