package com.myfshools.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record UpdateStudentGradeRequest(
        @NotNull Long studentId,
        @NotBlank String subject,
        @NotBlank String semester,
        String oralScores,
        String quizScores,
        String examScores,
        String semesterScore
) {
}
