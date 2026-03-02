package com.myfshools.backend.dto;

import java.math.BigDecimal;
import java.util.List;

public record DashboardResponse(
        String studentName,
        String className,
        String term,
        BigDecimal gpa,
        List<UpcomingClassDto> upcomingClasses
) {
}
