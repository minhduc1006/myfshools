package com.myfshools.backend.domain;

import jakarta.persistence.*;

import java.math.BigDecimal;

@Entity
@Table(name = "grades")
public class Grade {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser user;

    @Column(nullable = false)
    private String subject;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private SchoolSemester semester = SchoolSemester.SEMESTER_1;

    @Column(nullable = false, length = 4)
    private String letter;

    @Column(name = "oral_scores", length = 100)
    private String oralScores;

    @Column(name = "quiz_scores", length = 100)
    private String quizScores;

    @Column(name = "exam_scores", length = 100)
    private String examScores;

    @Column(name = "semester_score", precision = 4, scale = 2)
    private BigDecimal semesterScore;

    @Column(nullable = false, precision = 4, scale = 2)
    private BigDecimal score;

    @Column(length = 255)
    private String note;

    public Long getId() { return id; }
    public AppUser getUser() { return user; }
    public void setUser(AppUser user) { this.user = user; }
    public String getSubject() { return subject; }
    public void setSubject(String subject) { this.subject = subject; }
    public SchoolSemester getSemester() { return semester; }
    public void setSemester(SchoolSemester semester) { this.semester = semester; }
    public String getLetter() { return letter; }
    public void setLetter(String letter) { this.letter = letter; }
    public String getOralScores() { return oralScores; }
    public void setOralScores(String oralScores) { this.oralScores = oralScores; }
    public String getQuizScores() { return quizScores; }
    public void setQuizScores(String quizScores) { this.quizScores = quizScores; }
    public String getExamScores() { return examScores; }
    public void setExamScores(String examScores) { this.examScores = examScores; }
    public BigDecimal getSemesterScore() { return semesterScore; }
    public void setSemesterScore(BigDecimal semesterScore) { this.semesterScore = semesterScore; }
    public BigDecimal getScore() { return score; }
    public void setScore(BigDecimal score) { this.score = score; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
