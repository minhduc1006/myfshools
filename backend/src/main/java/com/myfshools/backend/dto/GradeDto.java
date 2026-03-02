package com.myfshools.backend.dto;

import java.math.BigDecimal;

public record GradeDto(
        Long id,
        String subject,
        String letter,
        String oralScores,
        String quizScores,
        String examScores,
        BigDecimal semesterScore,
        BigDecimal score,
        String note
) {
}
