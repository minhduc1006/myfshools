package com.myfshools.backend.service;

import com.myfshools.backend.domain.AppUser;
import com.myfshools.backend.domain.Conversation;
import com.myfshools.backend.domain.ConversationMember;
import com.myfshools.backend.domain.ConversationMessage;
import com.myfshools.backend.domain.Grade;
import com.myfshools.backend.domain.Homework;
import com.myfshools.backend.domain.HomeworkStatus;
import com.myfshools.backend.domain.Note;
import com.myfshools.backend.domain.ScheduleItem;
import com.myfshools.backend.domain.UpcomingClass;
import com.myfshools.backend.repository.AppUserRepository;
import com.myfshools.backend.repository.ConversationMemberRepository;
import com.myfshools.backend.repository.ConversationMessageRepository;
import com.myfshools.backend.repository.ConversationRepository;
import com.myfshools.backend.repository.GradeRepository;
import com.myfshools.backend.repository.HomeworkRepository;
import com.myfshools.backend.repository.NoteRepository;
import com.myfshools.backend.repository.ScheduleItemRepository;
import com.myfshools.backend.repository.UpcomingClassRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Component
public class DataSeeder implements CommandLineRunner {
    private final AppUserRepository appUserRepository;
    private final HomeworkRepository homeworkRepository;
    private final GradeRepository gradeRepository;
    private final NoteRepository noteRepository;
    private final UpcomingClassRepository upcomingClassRepository;
    private final ScheduleItemRepository scheduleItemRepository;
    private final ConversationRepository conversationRepository;
    private final ConversationMemberRepository conversationMemberRepository;
    private final ConversationMessageRepository conversationMessageRepository;
    private final PasswordEncoder passwordEncoder;

    public DataSeeder(AppUserRepository appUserRepository,
                      HomeworkRepository homeworkRepository,
                      GradeRepository gradeRepository,
                      NoteRepository noteRepository,
                      UpcomingClassRepository upcomingClassRepository,
                      ScheduleItemRepository scheduleItemRepository,
                      ConversationRepository conversationRepository,
                      ConversationMemberRepository conversationMemberRepository,
                      ConversationMessageRepository conversationMessageRepository,
                      PasswordEncoder passwordEncoder) {
        this.appUserRepository = appUserRepository;
        this.homeworkRepository = homeworkRepository;
        this.gradeRepository = gradeRepository;
        this.noteRepository = noteRepository;
        this.upcomingClassRepository = upcomingClassRepository;
        this.scheduleItemRepository = scheduleItemRepository;
        this.conversationRepository = conversationRepository;
        this.conversationMemberRepository = conversationMemberRepository;
        this.conversationMessageRepository = conversationMessageRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        clearChatData();

        AppUser userA = upsertUser("0386852628", "123456", "Nguyễn Văn A", "6A", "Năm học 2025-2026", "9.0", "A");
        AppUser userB = upsertUser("0900000001", "123456", "Trần Văn B", "6B", "Năm học 2025-2026", "8.7", "B");
        AppUser userC = upsertUser("0900000002", "123456", "Lê Thị C", "7A", "Năm học 2025-2026", "8.8", "C");
        AppUser userD = upsertUser("0900000003", "123456", "Phạm Thị D", "7B", "Năm học 2025-2026", "8.5", "D");
        AppUser userE = upsertUser("0900000004", "123456", "Hoàng Văn E", "8A", "Năm học 2025-2026", "8.4", "E");
        AppUser userF = upsertUser("0900000005", "123456", "Đỗ Thị F", "8B", "Năm học 2025-2026", "8.9", "F");
        AppUser userG = upsertUser("0900000006", "123456", "Bùi Văn G", "9A", "Năm học 2025-2026", "9.1", "G");
        AppUser userH = upsertUser("0900000007", "123456", "Võ Thị H", "9B", "Năm học 2025-2026", "8.6", "H");
        AppUser userI = upsertUser("0900000008", "123456", "Lương Minh I", "9B", "Năm học 2025-2026", "7.8", "I");

        List<AppUser> students = List.of(userA, userB, userC, userD, userE, userF, userG, userH, userI);
        for (AppUser student : students) {
            reseedAcademicData(student);
        }

        seedInitialDirectChat(userI, userA);
    }

    private AppUser upsertUser(String phone, String rawPassword, String fullName, String className, String term, String gpa, String initial) {
        AppUser user = appUserRepository.findByPhone(phone).orElseGet(() -> {
            AppUser u = new AppUser();
            u.setPhone(phone);
            return u;
        });

        user.setPasswordHash(passwordEncoder.encode(rawPassword));
        user.setFullName(fullName);
        user.setClassName(className);
        user.setTerm(term);
        user.setGpa(new BigDecimal(gpa));
        user.setAvatarInitial(initial);
        return appUserRepository.save(user);
    }

    private void clearChatData() {
        conversationMessageRepository.deleteAllInBatch();
        conversationMemberRepository.deleteAllInBatch();
        conversationRepository.deleteAllInBatch();
    }

    private void seedInitialDirectChat(AppUser sender, AppUser receiver) {
        Conversation conversation = new Conversation();
        conversation.setGroupChat(false);
        conversation.setName("");
        conversation.setCreatedBy(sender);
        conversation.setCreatedAt(Instant.now().minusSeconds(300));
        conversation.setUpdatedAt(Instant.now().minusSeconds(120));
        conversation = conversationRepository.save(conversation);

        ConversationMember senderMember = new ConversationMember();
        senderMember.setConversation(conversation);
        senderMember.setUser(sender);
        senderMember.setJoinedAt(Instant.now().minusSeconds(300));
        senderMember.setLastReadAt(Instant.now());
        conversationMemberRepository.save(senderMember);

        ConversationMember receiverMember = new ConversationMember();
        receiverMember.setConversation(conversation);
        receiverMember.setUser(receiver);
        receiverMember.setJoinedAt(Instant.now().minusSeconds(300));
        receiverMember.setLastReadAt(Instant.EPOCH);
        conversationMemberRepository.save(receiverMember);

        ConversationMessage message = new ConversationMessage();
        message.setConversation(conversation);
        message.setSender(sender);
        message.setText("Chào bạn, chiều nay mình muốn hỏi bài Toán. Bạn rảnh nhắn lại giúp mình nhé.");
        message.setSentAt(Instant.now().minusSeconds(120));
        conversationMessageRepository.save(message);
    }

    private void reseedAcademicData(AppUser user) {
        homeworkRepository.deleteAll(homeworkRepository.findByUserIdOrderByDueDateAsc(user.getId()));
        gradeRepository.deleteAll(gradeRepository.findByUserIdOrderBySubjectAsc(user.getId()));
        noteRepository.deleteAll(noteRepository.findByUserIdOrderByNoteDateDescIdDesc(user.getId()));
        upcomingClassRepository.deleteAll(upcomingClassRepository.findByUserIdOrderByIdAsc(user.getId()));
        scheduleItemRepository.deleteAll(scheduleItemRepository.findByUserIdOrderByIdAsc(user.getId()));

        seedHomeworks(user);
        seedGrades(user);
        refreshUserAverage(user);
        seedNotes(user);
        seedUpcomingClasses(user);
        seedTimetable(user);
    }

    private void seedHomeworks(AppUser user) {
        homeworkRepository.save(buildHomework(user, "Hoàn thành phiếu bài tập chương số hữu tỉ", "Toán", LocalDate.of(2026, 3, 3), HomeworkStatus.PENDING, 0, 1));
        homeworkRepository.save(buildHomework(user, "Viết đoạn văn kể về một người thân", "Ngữ văn", LocalDate.of(2026, 3, 4), HomeworkStatus.PENDING, 0, 1));
        homeworkRepository.save(buildHomework(user, "Ôn tập từ vựng Unit 8", "Tiếng Anh", LocalDate.of(2026, 2, 28), HomeworkStatus.OVERDUE, 0, 1));
        homeworkRepository.save(buildHomework(user, "Làm báo cáo thí nghiệm đơn giản", "Khoa học tự nhiên", LocalDate.of(2026, 2, 27), HomeworkStatus.SUBMITTED, 1, 1));
    }

    private void seedGrades(AppUser user) {
        gradeRepository.save(buildAcademicGrade(user, "Toán", "10 9", "9 9", "9 10", "9.0"));
        gradeRepository.save(buildAcademicGrade(user, "Ngữ văn", "8 8", "8 7", "8 8", "8.0"));
        gradeRepository.save(buildAcademicGrade(user, "Tiếng Anh", "9 9", "9 8", "9 9", "9.0"));
        gradeRepository.save(buildAcademicGrade(user, "Khoa học tự nhiên", "8 7", "8 8", "8 7", "8.0"));
        gradeRepository.save(buildAcademicGrade(user, "Lịch sử và Địa lý", "7 8", "7 7", "8", "7.5"));
        gradeRepository.save(buildAcademicGrade(user, "Tin học", "9", "9 8", "9", "8.8"));
        gradeRepository.save(buildAcademicGrade(user, "Công nghệ", "7", "7 8", "7", "7.3"));
        gradeRepository.save(buildAcademicGrade(user, "GDCD", "6 7", "6 6", "7", "6.5"));
        gradeRepository.save(buildPassFailGrade(user, "Giáo dục thể chất", "Đ"));
    }

    private void seedNotes(AppUser user) {
        noteRepository.save(buildNote(user, "Toán - Công thức hình học", "Ghi nhớ chu vi, diện tích các hình cơ bản...", "Tổng hợp công thức chu vi, diện tích và cách áp dụng vào bài tập.", LocalDate.of(2026, 3, 1)));
        noteRepository.save(buildNote(user, "Ngữ văn - Dàn ý bài văn", "Mở bài, thân bài, kết bài...", "Lập dàn ý kể về người thân và cách triển khai từng đoạn.", LocalDate.of(2026, 2, 28)));
        noteRepository.save(buildNote(user, "Tiếng Anh - Từ vựng", "Từ vựng về school activities...", "Ôn lại từ vựng và mẫu câu mô tả hoạt động ở trường.", LocalDate.of(2026, 2, 27)));
    }

    private void seedUpcomingClasses(AppUser user) {
        upcomingClassRepository.save(buildClass(user, "T2", 2, "Toán", "Phòng " + user.getClassName(), "08:00", "Cô Lan"));
        upcomingClassRepository.save(buildClass(user, "T3", 3, "Ngữ văn", "Phòng " + user.getClassName(), "13:25", "Thầy Minh"));
    }

    private void seedTimetable(AppUser user) {
        LocalDate start = LocalDate.of(2026, 1, 19);
        LocalDate end = LocalDate.of(2026, 5, 29);

        for (LocalDate date = start; !date.isAfter(end); date = date.plusDays(1)) {
            if (isWeekend(date)) {
                continue;
            }

            if (isTetHoliday(date)) {
                scheduleItemRepository.save(buildHolidaySchedule(user, date, "Nghỉ Tết Nguyên đán"));
                continue;
            }

            if (isNationalHoliday(date)) {
                scheduleItemRepository.save(buildHolidaySchedule(user, date, "Nghỉ lễ"));
                continue;
            }

            seedSchoolDay(user, date);
        }
    }

    private boolean isWeekend(LocalDate date) {
        return date.getDayOfWeek() == DayOfWeek.SATURDAY || date.getDayOfWeek() == DayOfWeek.SUNDAY;
    }

    private boolean isTetHoliday(LocalDate date) {
        LocalDate tetStart = LocalDate.of(2026, 2, 13);
        LocalDate tetEnd = LocalDate.of(2026, 2, 23);
        return !date.isBefore(tetStart) && !date.isAfter(tetEnd);
    }

    private boolean isNationalHoliday(LocalDate date) {
        return date.equals(LocalDate.of(2026, 4, 30)) || date.equals(LocalDate.of(2026, 5, 1));
    }

    private void seedSchoolDay(AppUser user, LocalDate date) {
        String room = user.getClassName();
        int weekdayIndex = date.getDayOfWeek().getValue() - 1;
        int weekOfSemester = calculateWeekOfSemester(date);

        switch (date.getDayOfWeek()) {
            case MONDAY -> {
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T2", "Thứ 2", "STEM", room, "08:00", "08:45", "Cô Hoa", "#2563EB"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T2", "Thứ 2", "Khoa học", room, "09:50", "10:35", "Thầy Sơn", "#10B981"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T2", "Thứ 2", "Tiếng Anh", room, "13:25", "14:10", "Cô Mai", "#F97316"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T2", "Thứ 2", "Giáo dục thể chất", "Sân trường", "15:15", "16:00", "Thầy Long", "#0EA5E9"));
            }
            case TUESDAY -> {
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T3", "Thứ 3", "Nghệ thuật", room, "08:00", "08:45", "Cô Thảo", "#EC4899"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T3", "Thứ 3", "Khoa học", room, "09:50", "10:35", "Thầy Sơn", "#10B981"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T3", "Thứ 3", "Tiếng Anh", room, "13:25", "14:10", "Cô Mai", "#F97316"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T3", "Thứ 3", "Giáo dục thể chất", "Sân trường", "15:15", "16:00", "Thầy Long", "#0EA5E9"));
            }
            case WEDNESDAY -> {
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T4", "Thứ 4", "Khoa học", room, "08:00", "08:45", "Thầy Sơn", "#10B981"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T4", "Thứ 4", "Lập trình", "Phòng tin học", "09:50", "10:35", "Cô Linh", "#7C3AED"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T4", "Thứ 4", "Tiếng Anh", room, "13:25", "14:10", "Cô Mai", "#F97316"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T4", "Thứ 4", "Giáo dục thể chất", "Sân trường", "15:15", "16:00", "Thầy Long", "#0EA5E9"));
            }
            case THURSDAY -> {
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T5", "Thứ 5", "Khoa học", room, "08:00", "08:45", "Thầy Sơn", "#10B981"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T5", "Thứ 5", "Lập trình", "Phòng tin học", "09:50", "10:35", "Cô Linh", "#7C3AED"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T5", "Thứ 5", "Tiếng Anh", room, "13:25", "14:10", "Cô Mai", "#F97316"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T5", "Thứ 5", "Giáo dục thể chất", "Sân trường", "15:15", "16:00", "Thầy Long", "#0EA5E9"));
            }
            case FRIDAY -> {
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T6", "Thứ 6", "Nghệ thuật", room, "08:00", "08:45", "Cô Thảo", "#EC4899"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T6", "Thứ 6", "STEM", room, "09:50", "10:35", "Cô Hoa", "#2563EB"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T6", "Thứ 6", "Hoạt động trải nghiệm", room, "13:25", "14:10", "Cô Hương", "#F59E0B"));
                scheduleItemRepository.save(buildSchedule(user, date, weekOfSemester, weekdayIndex, "T6", "Thứ 6", "Hoạt động trải nghiệm", room, "15:15", "16:00", "Cô Hương", "#F59E0B"));
            }
        }
    }

    private int calculateWeekOfSemester(LocalDate date) {
        LocalDate semesterStart = LocalDate.of(2026, 1, 19);
        long days = java.time.temporal.ChronoUnit.DAYS.between(semesterStart, date);
        return (int) (days / 7) + 1;
    }

    private ScheduleItem buildHolidaySchedule(AppUser user, LocalDate date, String title) {
        return buildSchedule(
                user,
                date,
                calculateWeekOfSemester(date),
                date.getDayOfWeek().getValue() - 1,
                shortLabel(date),
                fullLabel(date),
                title,
                "OFF",
                "00:00",
                "23:59",
                "Theo kế hoạch năm học",
                "#94A3B8"
        );
    }

    private Homework buildHomework(AppUser user, String title, String subject, LocalDate dueDate, HomeworkStatus status, int submitted, int total) {
        Homework hw = new Homework();
        hw.setUser(user);
        hw.setTitle(title);
        hw.setSubject(subject);
        hw.setDueDate(dueDate);
        hw.setStatus(status);
        hw.setProgressSubmitted(submitted);
        hw.setProgressTotal(total);
        return hw;
    }

    private Grade buildAcademicGrade(AppUser user, String subject, String oralScores, String quizScores, String examScores, String semesterScore) {
        BigDecimal semester = new BigDecimal(semesterScore);
        BigDecimal average = calculateSubjectAverage(oralScores, quizScores, examScores, semester);

        Grade grade = new Grade();
        grade.setUser(user);
        grade.setSubject(subject);
        grade.setLetter("");
        grade.setOralScores(oralScores);
        grade.setQuizScores(quizScores);
        grade.setExamScores(examScores);
        grade.setSemesterScore(semester);
        grade.setScore(average);
        grade.setNote(classifySubjectAverage(average));
        return grade;
    }

    private Grade buildPassFailGrade(AppUser user, String subject, String oralScores) {
        Grade grade = new Grade();
        grade.setUser(user);
        grade.setSubject(subject);
        grade.setLetter("");
        grade.setOralScores(oralScores);
        grade.setQuizScores("");
        grade.setExamScores("");
        grade.setSemesterScore(BigDecimal.TEN);
        grade.setScore(BigDecimal.TEN);
        grade.setNote("Đạt");
        return grade;
    }

    private BigDecimal calculateSubjectAverage(String oralScores, String quizScores, String examScores, BigDecimal semesterScore) {
        List<BigDecimal> hs1Scores = new ArrayList<>();
        hs1Scores.addAll(parseScores(oralScores));
        hs1Scores.addAll(parseScores(quizScores));
        List<BigDecimal> hs2Scores = parseScores(examScores);

        BigDecimal total = BigDecimal.ZERO;
        int totalWeight = 0;

        for (BigDecimal score : hs1Scores) {
            total = total.add(score);
            totalWeight += 1;
        }

        for (BigDecimal score : hs2Scores) {
            total = total.add(score.multiply(BigDecimal.valueOf(2)));
            totalWeight += 2;
        }

        total = total.add(semesterScore.multiply(BigDecimal.valueOf(3)));
        totalWeight += 3;

        if (totalWeight == 0) {
            return BigDecimal.ZERO;
        }

        return total.divide(BigDecimal.valueOf(totalWeight), 1, RoundingMode.HALF_UP);
    }

    private List<BigDecimal> parseScores(String raw) {
        List<BigDecimal> scores = new ArrayList<>();
        if (raw == null || raw.trim().isEmpty()) {
            return scores;
        }

        for (String token : raw.trim().split("\\s+")) {
            try {
                scores.add(new BigDecimal(token));
            } catch (NumberFormatException ignored) {
                // Ignore pass/fail style tokens such as Đ.
            }
        }
        return scores;
    }

    private String classifySubjectAverage(BigDecimal average) {
        double value = average.doubleValue();
        if (value >= 9.0) return "Giỏi";
        if (value >= 7.0) return "Khá";
        if (value >= 5.0) return "Trung bình";
        return "Yếu";
    }

    private void refreshUserAverage(AppUser user) {
        List<Grade> grades = gradeRepository.findByUserIdOrderBySubjectAsc(user.getId());
        BigDecimal average = calculateOverallAverage(grades);
        user.setGpa(average);
        appUserRepository.save(user);
    }

    private BigDecimal calculateOverallAverage(List<Grade> grades) {
        List<Grade> academicGrades = grades.stream()
                .filter(grade -> !"Đạt".equalsIgnoreCase(grade.getNote()))
                .toList();

        if (academicGrades.isEmpty()) {
            return BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        }

        BigDecimal total = BigDecimal.ZERO;
        for (Grade grade : academicGrades) {
            total = total.add(grade.getScore());
        }

        return total.divide(BigDecimal.valueOf(academicGrades.size()), 1, RoundingMode.HALF_UP);
    }

    private Note buildNote(AppUser user, String title, String preview, String content, LocalDate noteDate) {
        Note note = new Note();
        note.setUser(user);
        note.setTitle(title);
        note.setPreview(preview);
        note.setContent(content);
        note.setNoteDate(noteDate);
        return note;
    }

    private UpcomingClass buildClass(AppUser user, String dayLabel, int dayNumber, String subject, String room, String startTime, String teacher) {
        UpcomingClass c = new UpcomingClass();
        c.setUser(user);
        c.setDayLabel(dayLabel);
        c.setDayNumber(dayNumber);
        c.setSubject(subject);
        c.setRoom(room);
        c.setStartTime(startTime);
        c.setTeacher(teacher);
        return c;
    }

    private String shortLabel(LocalDate date) {
        return switch (date.getDayOfWeek()) {
            case MONDAY -> "T2";
            case TUESDAY -> "T3";
            case WEDNESDAY -> "T4";
            case THURSDAY -> "T5";
            case FRIDAY -> "T6";
            case SATURDAY -> "T7";
            case SUNDAY -> "CN";
        };
    }

    private String fullLabel(LocalDate date) {
        return switch (date.getDayOfWeek()) {
            case MONDAY -> "Thứ 2";
            case TUESDAY -> "Thứ 3";
            case WEDNESDAY -> "Thứ 4";
            case THURSDAY -> "Thứ 5";
            case FRIDAY -> "Thứ 6";
            case SATURDAY -> "Thứ 7";
            case SUNDAY -> "Chủ nhật";
        };
    }

    private ScheduleItem buildSchedule(AppUser user, LocalDate scheduleDate, int weekOfSemester, int dayOfWeekIndex, String dayShort, String dayFull,
                                       String subject, String room, String startTime, String endTime, String teacher, String colorHex) {
        ScheduleItem s = new ScheduleItem();
        s.setUser(user);
        s.setDayOfWeekIndex(dayOfWeekIndex);
        s.setDayShort(dayShort);
        s.setDayFull(dayFull);
        s.setDayOfMonth(scheduleDate.getDayOfMonth());
        s.setScheduleDate(scheduleDate);
        s.setWeekOfSemester(weekOfSemester);
        s.setSubject(subject);
        s.setRoom(room);
        s.setStartTime(startTime);
        s.setEndTime(endTime);
        s.setTeacher(teacher);
        s.setColorHex(colorHex);
        return s;
    }
}
