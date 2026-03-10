package com.myfshools.backend.dto;

import java.math.BigDecimal;

public record StudentGradeRowDto(
        Long studentId,
        String studentPhone,
        String studentName,
        String className,
        String subject,
        String semester,
        String oralScores,
        String quizScores,
        String examScores,
        BigDecimal semesterScore,
        BigDecimal averageScore,
        String note
) {
}
