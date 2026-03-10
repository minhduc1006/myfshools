package com.myfshools.backend.service;

import com.myfshools.backend.domain.*;
import com.myfshools.backend.dto.HomeworkClassReportDto;
import com.myfshools.backend.dto.HomeworkStudentStatusDto;
import com.myfshools.backend.dto.StudentGradeRowDto;
import com.myfshools.backend.dto.TuitionStudentStatusDto;
import com.myfshools.backend.dto.TuitionClassSummaryDto;
import com.myfshools.backend.dto.UpdateStudentGradeRequest;
import com.myfshools.backend.repository.AppUserRepository;
import com.myfshools.backend.repository.GradeRepository;
import com.myfshools.backend.repository.HomeworkRepository;
import com.myfshools.backend.repository.TuitionInvoiceRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class TeacherAcademicService {
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    private final CurrentUserService currentUserService;
    private final AppUserRepository appUserRepository;
    private final GradeRepository gradeRepository;
    private final HomeworkRepository homeworkRepository;
    private final TuitionInvoiceRepository tuitionInvoiceRepository;

    public TeacherAcademicService(CurrentUserService currentUserService,
                                  AppUserRepository appUserRepository,
                                  GradeRepository gradeRepository,
                                  HomeworkRepository homeworkRepository,
                                  TuitionInvoiceRepository tuitionInvoiceRepository) {
        this.currentUserService = currentUserService;
        this.appUserRepository = appUserRepository;
        this.gradeRepository = gradeRepository;
        this.homeworkRepository = homeworkRepository;
        this.tuitionInvoiceRepository = tuitionInvoiceRepository;
    }

    public List<StudentGradeRowDto> classGrades(String className, String semester) {
        AppUser me = currentUserService.getRequiredUser();
        UserRole role = me.getRole() == null ? UserRole.STUDENT : me.getRole();
        if (role != UserRole.HOMEROOM_TEACHER && role != UserRole.EXAM_OFFICER) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chỉ giáo viên chủ nhiệm hoặc khảo thí mới được xem toàn bộ điểm lớp");
        }
        if (role == UserRole.HOMEROOM_TEACHER && !className.equalsIgnoreCase(me.getManagedClass())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn chỉ được xem lớp chủ nhiệm của mình");
        }
        SchoolSemester parsed = parseSemester(semester);
        return gradeRepository.findByUserClassNameAndSemesterOrderByUserFullNameAscSubjectAsc(className, parsed)
                .stream()
                .map(this::toStudentGradeRow)
                .toList();
    }

    public List<StudentGradeRowDto> subjectGrades(String className, String semester) {
        AppUser me = currentUserService.getRequiredUser();
        UserRole role = me.getRole() == null ? UserRole.STUDENT : me.getRole();
        if (role != UserRole.SUBJECT_TEACHER && role != UserRole.EXAM_OFFICER) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chỉ giáo viên bộ môn hoặc khảo thí mới được xem bảng điểm bộ môn");
        }
        String subject = role == UserRole.EXAM_OFFICER ? null : me.getSubjectSpecialty();
        if (subject == null || subject.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Không xác định được môn học của giáo viên");
        }
        SchoolSemester parsed = parseSemester(semester);
        List<Grade> grades = role == UserRole.EXAM_OFFICER
                ? gradeRepository.findByUserClassNameAndSemesterOrderByUserFullNameAscSubjectAsc(className, parsed)
                : gradeRepository.findByUserClassNameAndSemesterAndSubjectOrderByUserFullNameAsc(className, parsed, subject);
        return grades.stream().map(this::toStudentGradeRow).toList();
    }

    @Transactional
    public StudentGradeRowDto updateGrade(UpdateStudentGradeRequest request) {
        AppUser me = currentUserService.getRequiredUser();
        AppUser student = appUserRepository.findById(request.studentId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy học sinh"));
        if ((student.getRole() == null ? UserRole.STUDENT : student.getRole()) != UserRole.STUDENT) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Tài khoản này không phải học sinh");
        }

        String subject = request.subject().trim();
        enforceTeacherPermission(me, student.getClassName(), subject);

        SchoolSemester semester = parseSemester(request.semester());
        Grade grade = gradeRepository.findByUserIdAndSubjectAndSemester(student.getId(), subject, semester)
                .orElseGet(() -> {
                    Grade created = new Grade();
                    created.setUser(student);
                    created.setSubject(subject);
                    created.setSemester(semester);
                    created.setLetter("");
                    return created;
                });

        grade.setOralScores(safeScores(request.oralScores()));
        grade.setQuizScores(safeScores(request.quizScores()));
        grade.setExamScores(safeScores(request.examScores()));
        grade.setSemesterScore(parseDecimalOrNull(request.semesterScore()));
        grade.setScore(calculateSubjectAverage(grade.getOralScores(), grade.getQuizScores(), grade.getExamScores(), grade.getSemesterScore()));
        grade.setNote(classify(grade.getScore()));
        grade = gradeRepository.save(grade);
        refreshStudentGpa(student);
        return toStudentGradeRow(grade);
    }

    @Transactional
    public List<StudentGradeRowDto> importGradesCsv(String csvContent, String semester) {
        if (csvContent == null || csvContent.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Nội dung file rỗng");
        }
        List<StudentGradeRowDto> updated = new ArrayList<>();
        String[] lines = csvContent.replace("\r", "").split("\n");
        for (int i = 0; i < lines.length; i++) {
            String line = lines[i].trim();
            if (line.isEmpty()) continue;
            if (i == 0 && line.toLowerCase(Locale.ROOT).contains("studentphone")) continue;

            String[] parts = line.split(",", -1);
            if (parts.length < 6) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Dòng CSV không hợp lệ: " + line);
            }

            AppUser student = appUserRepository.findByPhone(parts[0].trim())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy học sinh: " + parts[0].trim()));

            updated.add(updateGrade(new UpdateStudentGradeRequest(
                    student.getId(),
                    parts[1].trim(),
                    semester,
                    parts[2].trim(),
                    parts[3].trim(),
                    parts[4].trim(),
                    parts[5].trim()
            )));
        }
        return updated;
    }

    public List<TuitionClassSummaryDto> tuitionOverviewByClass() {
        AppUser me = currentUserService.getRequiredUser();
        if ((me.getRole() == null ? UserRole.STUDENT : me.getRole()) != UserRole.EXAM_OFFICER) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chỉ khảo thí mới được theo dõi học phí theo lớp");
        }

        Map<String, TuitionClassSummaryDto> summary = new LinkedHashMap<>();
        for (AppUser student : appUserRepository.findAllByOrderByClassNameAscFullNameAsc()) {
            if (student.getRole() != UserRole.STUDENT) continue;
            List<TuitionInvoice> invoices = tuitionInvoiceRepository.findByUserIdOrderByDueDateAsc(student.getId());
            int totalAmount = invoices.stream().mapToInt(TuitionInvoice::getAmount).sum();
            int paidAmount = invoices.stream()
                    .filter(invoice -> invoice.getStatus() == TuitionInvoiceStatus.PAID)
                    .mapToInt(TuitionInvoice::getAmount)
                    .sum();
            boolean paid = invoices.stream().allMatch(invoice -> invoice.getStatus() == TuitionInvoiceStatus.PAID);
            boolean pending = invoices.stream().anyMatch(invoice -> invoice.getStatus() == TuitionInvoiceStatus.PENDING);

            TuitionClassSummaryDto current = summary.get(student.getClassName());
            if (current == null) {
                current = new TuitionClassSummaryDto(student.getClassName(), 0, 0, 0, 0, 0, 0);
            }

            summary.put(student.getClassName(), new TuitionClassSummaryDto(
                    current.className(),
                    current.totalStudents() + 1,
                    current.paidStudents() + (paid ? 1 : 0),
                    current.pendingStudents() + (!paid && pending ? 1 : 0),
                    current.unpaidStudents() + (!paid && !pending ? 1 : 0),
                    current.totalAmount() + totalAmount,
                    current.paidAmount() + paidAmount
            ));
        }
        return new ArrayList<>(summary.values());
    }

    public List<TuitionStudentStatusDto> tuitionDetailsByClass(String className) {
        AppUser me = currentUserService.getRequiredUser();
        if ((me.getRole() == null ? UserRole.STUDENT : me.getRole()) != UserRole.EXAM_OFFICER) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chá»‰ kháº£o thÃ­ má»›i Ä‘Æ°á»£c xem danh sÃ¡ch nÃ´p há»c phÃ­ theo lá»›p");
        }
        if (className == null || className.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Lá»›p khÃ´ng há»£p lá»‡");
        }

        List<TuitionStudentStatusDto> result = new ArrayList<>();
        for (AppUser student : appUserRepository.findByClassNameOrderByFullNameAsc(className.trim())) {
            if (student.getRole() != UserRole.STUDENT) {
                continue;
            }
            int totalAmount = 0;
            int paidAmount = 0;
            boolean anyPending = false;

            for (TuitionInvoice invoice : tuitionInvoiceRepository.findByUserIdOrderByDueDateAsc(student.getId())) {
                totalAmount += invoice.getAmount() == null ? 0 : invoice.getAmount();
                if (invoice.getStatus() == TuitionInvoiceStatus.PAID) {
                    paidAmount += invoice.getAmount() == null ? 0 : invoice.getAmount();
                } else if (invoice.getStatus() == TuitionInvoiceStatus.PENDING) {
                    anyPending = true;
                }
            }

            String status;
            if (totalAmount == 0) {
                status = "ChÆ°a cÃ³ hÃ³a Ä‘Æ¡n";
            } else if (paidAmount >= totalAmount) {
                status = "ÄÃ£ nÃ´p";
            } else if (anyPending) {
                status = "Chá» xÃ¡c nháº­n";
            } else {
                status = "ChÆ°a nÃ´p";
            }

            result.add(new TuitionStudentStatusDto(
                    student.getId(),
                    student.getPhone(),
                    student.getFullName(),
                    student.getClassName(),
                    status,
                    totalAmount,
                    paidAmount
            ));
        }
        result.sort((a, b) -> {
            int byStatus = statusRank(a.status()) - statusRank(b.status());
            if (byStatus != 0) return byStatus;
            return (a.studentName() == null ? "" : a.studentName())
                    .compareToIgnoreCase(b.studentName() == null ? "" : b.studentName());
        });
        return result;
    }

    private int statusRank(String status) {
        if (status == null) return 9;
        if (status.contains("ChÆ°a nÃ´p")) return 0;
        if (status.contains("Chá»")) return 1;
        if (status.contains("ChÆ°a cÃ³")) return 2;
        if (status.contains("ÄÃ£ nÃ´p")) return 3;
        return 9;
    }

    public List<HomeworkClassReportDto> homeworkReportsByClass() {
        AppUser me = currentUserService.getRequiredUser();
        List<HomeworkClassReportDto> reports = new ArrayList<>();
        for (String className : accessibleHomeworkClasses(me)) {
            reports.add(buildHomeworkClassReport(className, me));
        }
        return reports;
    }

    public List<HomeworkStudentStatusDto> homeworkDetailsByClass(String className) {
        AppUser me = currentUserService.getRequiredUser();
        enforceHomeworkReportPermission(me, className);
        String subjectFilter = homeworkSubjectFilter(me);
        LocalDate today = LocalDate.now();

        return homeworkRepository.findByUserClassNameOrderBySubjectAscDueDateAscUserFullNameAsc(className).stream()
                .filter(homework -> subjectFilter == null || subjectFilter.equalsIgnoreCase(homework.getSubject()))
                .map(homework -> new HomeworkStudentStatusDto(
                        homework.getUser().getPhone(),
                        homework.getUser().getFullName(),
                        homework.getUser().getClassName(),
                        homework.getTitle(),
                        homework.getSubject(),
                        homework.getDueDate().format(DATE_FMT),
                        homeworkStatusLabel(homework, today)
                ))
                .toList();
    }

    private void enforceTeacherPermission(AppUser me, String className, String subject) {
        UserRole role = me.getRole() == null ? UserRole.STUDENT : me.getRole();
        if (role == UserRole.EXAM_OFFICER) return;
        if (role == UserRole.HOMEROOM_TEACHER) {
            if (me.getManagedClass() == null || !me.getManagedClass().equalsIgnoreCase(className)) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn chỉ được nhập điểm lớp chủ nhiệm");
            }
            return;
        }
        if (role == UserRole.SUBJECT_TEACHER) {
            if (me.getSubjectSpecialty() == null || !me.getSubjectSpecialty().equalsIgnoreCase(subject)) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn chỉ được nhập điểm môn mình phụ trách");
            }
            return;
        }
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền nhập điểm");
    }

    private List<String> accessibleHomeworkClasses(AppUser me) {
        UserRole role = me.getRole() == null ? UserRole.STUDENT : me.getRole();
        if (role == UserRole.HOMEROOM_TEACHER) {
            if (me.getManagedClass() == null || me.getManagedClass().isBlank()) {
                return List.of();
            }
            return List.of(me.getManagedClass());
        }
        if (role == UserRole.SUBJECT_TEACHER || role == UserRole.EXAM_OFFICER) {
            return appUserRepository.findAllByOrderByClassNameAscFullNameAsc().stream()
                    .filter(user -> user.getRole() == UserRole.STUDENT)
                    .map(AppUser::getClassName)
                    .distinct()
                    .toList();
        }
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Ban khong co quyen xem bao cao bai tap");
    }

    private void enforceHomeworkReportPermission(AppUser me, String className) {
        if (!accessibleHomeworkClasses(me).contains(className)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Ban khong co quyen xem bao cao lop nay");
        }
    }

    private HomeworkClassReportDto buildHomeworkClassReport(String className, AppUser me) {
        String subjectFilter = homeworkSubjectFilter(me);
        LocalDate today = LocalDate.now();
        int totalStudents = (int) appUserRepository.findByClassNameOrderByFullNameAsc(className).stream()
                .filter(user -> user.getRole() == UserRole.STUDENT)
                .count();
        int submitted = 0;
        int pending = 0;
        int overdue = 0;

        for (Homework homework : homeworkRepository.findByUserClassNameOrderBySubjectAscDueDateAscUserFullNameAsc(className)) {
            if (subjectFilter != null && !subjectFilter.equalsIgnoreCase(homework.getSubject())) {
                continue;
            }
            switch (homeworkStatusLabel(homework, today)) {
                case "Đã nộp" -> submitted++;
                case "Quá hạn" -> overdue++;
                default -> pending++;
            }
        }

        return new HomeworkClassReportDto(className, totalStudents, submitted, pending, overdue);
    }

    private String homeworkSubjectFilter(AppUser me) {
        UserRole role = me.getRole() == null ? UserRole.STUDENT : me.getRole();
        if (role == UserRole.SUBJECT_TEACHER) {
            if (me.getSubjectSpecialty() == null || me.getSubjectSpecialty().isBlank()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Khong xac dinh duoc mon giao vien phu trach");
            }
            return me.getSubjectSpecialty();
        }
        return null;
    }

    private String homeworkStatusLabel(Homework homework, LocalDate today) {
        if (homework.getStatus() == HomeworkStatus.SUBMITTED) {
            return "Đã nộp";
        }
        if (homework.getDueDate() != null && homework.getDueDate().isBefore(today)) {
            return "Quá hạn";
        }
        return "Chưa nộp";
    }

    private StudentGradeRowDto toStudentGradeRow(Grade grade) {
        return new StudentGradeRowDto(
                grade.getUser().getId(),
                grade.getUser().getPhone(),
                grade.getUser().getFullName(),
                grade.getUser().getClassName(),
                grade.getSubject(),
                grade.getSemester() == SchoolSemester.SEMESTER_2 ? "2" : "1",
                grade.getOralScores(),
                grade.getQuizScores(),
                grade.getExamScores(),
                grade.getSemesterScore(),
                grade.getScore(),
                grade.getNote()
        );
    }

    private SchoolSemester parseSemester(String semester) {
        if (semester == null || semester.isBlank() || "1".equals(semester.trim()) || "hk1".equalsIgnoreCase(semester.trim())) {
            return SchoolSemester.SEMESTER_1;
        }
        if ("2".equals(semester.trim()) || "hk2".equalsIgnoreCase(semester.trim())) {
            return SchoolSemester.SEMESTER_2;
        }
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Học kỳ không hợp lệ");
    }

    private String safeScores(String value) {
        return value == null ? "" : value.trim();
    }

    private BigDecimal parseDecimalOrNull(String value) {
        try {
            if (value == null || value.trim().isEmpty()) return null;
            return new BigDecimal(value.trim());
        } catch (NumberFormatException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Điểm học kỳ không hợp lệ");
        }
    }

    private BigDecimal calculateSubjectAverage(String oralScores, String quizScores, String examScores, BigDecimal semesterScore) {
        List<BigDecimal> hs1 = new ArrayList<>();
        hs1.addAll(parseScores(oralScores));
        hs1.addAll(parseScores(quizScores));
        List<BigDecimal> hs2 = parseScores(examScores);

        BigDecimal total = BigDecimal.ZERO;
        int weight = 0;
        for (BigDecimal score : hs1) {
            total = total.add(score);
            weight += 1;
        }
        for (BigDecimal score : hs2) {
            total = total.add(score.multiply(BigDecimal.valueOf(2)));
            weight += 2;
        }
        if (semesterScore != null) {
            total = total.add(semesterScore.multiply(BigDecimal.valueOf(3)));
            weight += 3;
        }
        if (weight == 0) return BigDecimal.ZERO;
        return total.divide(BigDecimal.valueOf(weight), 1, RoundingMode.HALF_UP);
    }

    private List<BigDecimal> parseScores(String raw) {
        List<BigDecimal> scores = new ArrayList<>();
        if (raw == null || raw.trim().isEmpty()) return scores;
        for (String token : raw.trim().split("\\s+")) {
            try {
                scores.add(new BigDecimal(token));
            } catch (NumberFormatException ignored) {
            }
        }
        return scores;
    }

    private String classify(BigDecimal average) {
        double value = average.doubleValue();
        if (value >= 9.0) return "Giỏi";
        if (value >= 7.0) return "Khá";
        if (value >= 5.0) return "Trung bình";
        return "Yếu";
    }

    private void refreshStudentGpa(AppUser student) {
        List<Grade> grades = gradeRepository.findByUserIdAndSemesterOrderBySubjectAsc(student.getId(), SchoolSemester.SEMESTER_1);
        if (grades.isEmpty()) {
            student.setGpa(BigDecimal.ZERO);
            appUserRepository.save(student);
            return;
        }
        BigDecimal total = BigDecimal.ZERO;
        int count = 0;
        for (Grade grade : grades) {
            if ("Dat".equalsIgnoreCase(grade.getNote())) continue;
            total = total.add(grade.getScore());
            count++;
        }
        student.setGpa(count == 0 ? BigDecimal.ZERO : total.divide(BigDecimal.valueOf(count), 1, RoundingMode.HALF_UP));
        appUserRepository.save(student);
    }
}
