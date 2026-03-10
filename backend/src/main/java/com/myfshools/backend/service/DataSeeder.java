package com.myfshools.backend.service;

import com.myfshools.backend.domain.AlertNotice;
import com.myfshools.backend.domain.AlertType;
import com.myfshools.backend.domain.AppUser;
import com.myfshools.backend.domain.Grade;
import com.myfshools.backend.domain.Homework;
import com.myfshools.backend.domain.HomeworkStatus;
import com.myfshools.backend.domain.Note;
import com.myfshools.backend.domain.Role;
import com.myfshools.backend.domain.SchoolSemester;
import com.myfshools.backend.domain.ScheduleItem;
import com.myfshools.backend.domain.ServiceRequest;
import com.myfshools.backend.domain.ServiceRequestCategory;
import com.myfshools.backend.domain.ServiceRequestStatus;
import com.myfshools.backend.domain.TeacherAssignment;
import com.myfshools.backend.domain.TuitionInvoice;
import com.myfshools.backend.domain.TuitionInvoiceStatus;
import com.myfshools.backend.domain.UpcomingClass;
import com.myfshools.backend.domain.UserRole;
import com.myfshools.backend.domain.ChatMessage;
import com.myfshools.backend.domain.ChatThread;
import com.myfshools.backend.domain.Conversation;
import com.myfshools.backend.domain.ConversationMember;
import com.myfshools.backend.domain.ConversationMessage;
import com.myfshools.backend.repository.AlertNoticeRepository;
import com.myfshools.backend.repository.AppUserRepository;
import com.myfshools.backend.repository.ChatMessageRepository;
import com.myfshools.backend.repository.ChatThreadRepository;
import com.myfshools.backend.repository.ConversationMemberRepository;
import com.myfshools.backend.repository.ConversationMessageRepository;
import com.myfshools.backend.repository.ConversationRepository;
import com.myfshools.backend.repository.GradeRepository;
import com.myfshools.backend.repository.HomeworkRepository;
import com.myfshools.backend.repository.RoleRepository;
import com.myfshools.backend.repository.NoteRepository;
import com.myfshools.backend.repository.ScheduleItemRepository;
import com.myfshools.backend.repository.ServiceRequestRepository;
import com.myfshools.backend.repository.TeacherAssignmentRepository;
import com.myfshools.backend.repository.TuitionInvoiceRepository;
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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class DataSeeder implements CommandLineRunner {
    private static final String SCHOOL_TERM = "Năm học 2025-2026";

    private final AppUserRepository appUserRepository;
    private final HomeworkRepository homeworkRepository;
    private final GradeRepository gradeRepository;
    private final NoteRepository noteRepository;
    private final UpcomingClassRepository upcomingClassRepository;
    private final ScheduleItemRepository scheduleItemRepository;
    private final ConversationRepository conversationRepository;
    private final ConversationMemberRepository conversationMemberRepository;
    private final ConversationMessageRepository conversationMessageRepository;
    private final ChatThreadRepository chatThreadRepository;
    private final ChatMessageRepository chatMessageRepository;
    private final AlertNoticeRepository alertNoticeRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final ServiceRequestRepository serviceRequestRepository;
    private final TuitionInvoiceRepository tuitionInvoiceRepository;
    private final RoleRepository roleRepository;
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
                      ChatThreadRepository chatThreadRepository,
                      ChatMessageRepository chatMessageRepository,
                      AlertNoticeRepository alertNoticeRepository,
                      TeacherAssignmentRepository teacherAssignmentRepository,
                      ServiceRequestRepository serviceRequestRepository,
                      TuitionInvoiceRepository tuitionInvoiceRepository,
                      RoleRepository roleRepository,
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
        this.chatThreadRepository = chatThreadRepository;
        this.chatMessageRepository = chatMessageRepository;
        this.alertNoticeRepository = alertNoticeRepository;
        this.teacherAssignmentRepository = teacherAssignmentRepository;
        this.serviceRequestRepository = serviceRequestRepository;
        this.tuitionInvoiceRepository = tuitionInvoiceRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        clearAll();
        Map<UserRole, Role> roles = seedRoles();

        Map<String, AppUser> homeroomTeachers = new LinkedHashMap<>();
        Map<String, AppUser> subjectTeachers = seedSubjectTeachers(roles);
        AppUser examOfficer = createUser(
                "0990000000",
                "123456",
                "Cô Khảo thí",
                "ADMIN",
                roles.get(UserRole.EXAM_OFFICER),
                "",
                "",
                "0.0",
                "K"
        );

        for (int grade = 6; grade <= 9; grade++) {
            for (String section : List.of("A", "B")) {
                String className = grade + section;
                AppUser homeroom = createUser(
                        buildHomeroomPhone(grade, section),
                        "123456",
                        "GVCN " + className,
                        className,
                        roles.get(UserRole.HOMEROOM_TEACHER),
                        className,
                        "Chủ nhiệm",
                        "0.0",
                        section
                );
                homeroomTeachers.put(className, homeroom);

                for (int index = 1; index <= 15; index++) {
                    AppUser student = createStudent(grade, section, index, roles);
                    seedStudentAcademicData(student, grade, index);
                    seedCampusData(student, index);
                }
            }
        }

        seedTeacherAssignments(homeroomTeachers, subjectTeachers);
        seedTeacherDirectChat(examOfficer, homeroomTeachers.get("6A"));
    }

    private Map<UserRole, Role> seedRoles() {
        Map<UserRole, Role> roles = new LinkedHashMap<>();
        for (UserRole role : UserRole.values()) {
            roles.put(role, roleRepository.findByCode(role.name())
                    .orElseGet(() -> roleRepository.save(new Role(role.name()))));
        }
        return roles;
    }

    private void clearAll() {
        chatMessageRepository.deleteAllInBatch();
        chatThreadRepository.deleteAllInBatch();
        conversationMessageRepository.deleteAllInBatch();
        conversationMemberRepository.deleteAllInBatch();
        conversationRepository.deleteAllInBatch();
        teacherAssignmentRepository.deleteAllInBatch();
        alertNoticeRepository.deleteAllInBatch();
        serviceRequestRepository.deleteAllInBatch();
        tuitionInvoiceRepository.deleteAllInBatch();
        homeworkRepository.deleteAllInBatch();
        gradeRepository.deleteAllInBatch();
        noteRepository.deleteAllInBatch();
        upcomingClassRepository.deleteAllInBatch();
        scheduleItemRepository.deleteAllInBatch();
        appUserRepository.deleteAllInBatch();
    }

    private Map<String, AppUser> seedSubjectTeachers(Map<UserRole, Role> roles) {
        Map<String, AppUser> teachers = new LinkedHashMap<>();
        teachers.put("Toán", createUser("0970000001", "123456", "Thầy Toán", "ALL", roles.get(UserRole.SUBJECT_TEACHER), "", "Toán", "0.0", "T"));
        teachers.put("Ngữ văn", createUser("0970000002", "123456", "Cô Văn", "ALL", roles.get(UserRole.SUBJECT_TEACHER), "", "Ngữ văn", "0.0", "V"));
        teachers.put("Tiếng Anh", createUser("0970000003", "123456", "Cô Anh", "ALL", roles.get(UserRole.SUBJECT_TEACHER), "", "Tiếng Anh", "0.0", "A"));
        teachers.put("Khoa học tự nhiên", createUser("0970000004", "123456", "Thầy KHTN", "ALL", roles.get(UserRole.SUBJECT_TEACHER), "", "Khoa học tự nhiên", "0.0", "K"));
        teachers.put("Tin học", createUser("0970000005", "123456", "Cô Tin", "ALL", roles.get(UserRole.SUBJECT_TEACHER), "", "Tin học", "0.0", "I"));
        return teachers;
    }

    private AppUser createStudent(int grade, String section, int index, Map<UserRole, Role> roles) {
        String className = grade + section;
        return createUser(
                buildStudentPhone(grade, section, index),
                "123456",
                "Học sinh " + className + "-" + String.format("%02d", index),
                className,
                roles.get(UserRole.STUDENT),
                "",
                "",
                "8.0",
                String.valueOf(index).substring(0, 1)
        );
    }

    private String buildStudentPhone(int grade, String section, int index) {
        String sectionCode = "A".equals(section) ? "1" : "2";
        return "0" + grade + sectionCode + "000" + String.format("%04d", index);
    }

    private String buildHomeroomPhone(int grade, String section) {
        String sectionCode = "A".equals(section) ? "1" : "2";
        return "098" + grade + sectionCode + "00000";
    }

    private AppUser createUser(String phone,
                               String rawPassword,
                               String fullName,
                               String className,
                               Role role,
                               String managedClass,
                               String subjectSpecialty,
                               String gpa,
                               String initial) {
        AppUser user = new AppUser();
        user.setPhone(phone);
        user.setPasswordHash(passwordEncoder.encode(rawPassword));
        user.setFullName(fullName);
        user.setClassName(className);
        user.setRoleEntity(role);
        user.setManagedClass(managedClass == null || managedClass.isBlank() ? null : managedClass);
        user.setSubjectSpecialty(subjectSpecialty == null || subjectSpecialty.isBlank() ? null : subjectSpecialty);
        user.setTerm(SCHOOL_TERM);
        user.setGpa(new BigDecimal(gpa));
        user.setAvatarInitial(initial.substring(0, 1).toUpperCase());
        return appUserRepository.save(user);
    }

    private void seedStudentAcademicData(AppUser student, int grade, int index) {
        seedHomeworks(student, grade);
        seedGrades(student, index);
        seedNotes(student);
        seedUpcomingClasses(student);
        seedTimetable(student);
    }

    private void seedCampusData(AppUser student, int index) {
        seedAlerts(student);
        seedServiceRequests(student);
        seedTuition(student, index);
    }

    private void seedHomeworks(AppUser user, int grade) {
        homeworkRepository.save(buildHomework(user, "Ôn tập chương " + grade, "Toán", LocalDate.of(2026, 3, 6), HomeworkStatus.PENDING, 0, 1));
        homeworkRepository.save(buildHomework(user, "Viết đoạn văn ngắn", "Ngữ văn", LocalDate.of(2026, 3, 7), HomeworkStatus.PENDING, 0, 1));
        homeworkRepository.save(buildHomework(user, "Bài tập từ vựng Unit 8", "Tiếng Anh", LocalDate.of(2026, 2, 28), HomeworkStatus.SUBMITTED, 1, 1));
    }

    private void seedGrades(AppUser user, int index) {
        List<Grade> semesterOne = new ArrayList<>();
        semesterOne.add(buildGrade(user, "Toán", SchoolSemester.SEMESTER_1, 8.2 + adjust(index), "9 8", "8 8", "8 9", "Khá"));
        semesterOne.add(buildGrade(user, "Ngữ văn", SchoolSemester.SEMESTER_1, 7.8 + adjust(index), "8 8", "8 7", "8 8", "Khá"));
        semesterOne.add(buildGrade(user, "Tiếng Anh", SchoolSemester.SEMESTER_1, 8.0 + adjust(index), "8 9", "8 8", "8 9", "Khá"));
        semesterOne.add(buildGrade(user, "Khoa học tự nhiên", SchoolSemester.SEMESTER_1, 7.9 + adjust(index), "8 8", "8 8", "8 8", "Khá"));
        semesterOne.add(buildGrade(user, "Lịch sử và Địa lý", SchoolSemester.SEMESTER_1, 7.4 + adjust(index), "7 8", "7 7", "8", "Khá"));
        semesterOne.add(buildGrade(user, "Tin học", SchoolSemester.SEMESTER_1, 8.4 + adjust(index), "9", "8 9", "9", "Khá"));
        semesterOne.add(buildGrade(user, "GDCD", SchoolSemester.SEMESTER_1, 7.0 + adjust(index), "7 7", "7 7", "7", "Khá"));
        semesterOne.add(buildPassFailGrade(user, "Giáo dục thể chất", SchoolSemester.SEMESTER_1));

        List<Grade> semesterTwo = new ArrayList<>();
        semesterTwo.add(buildGrade(user, "Toán", SchoolSemester.SEMESTER_2, null, semesterTwoOralScores(index, "8 8"), semesterTwoQuizScores("8 7"), "8", "Tạm tính"));
        semesterTwo.add(buildGrade(user, "Ngữ văn", SchoolSemester.SEMESTER_2, null, semesterTwoOralScores(index, "8 7"), semesterTwoQuizScores("7 7"), "8", "Tạm tính"));
        semesterTwo.add(buildGrade(user, "Tiếng Anh", SchoolSemester.SEMESTER_2, null, semesterTwoOralScores(index, "8 8"), semesterTwoQuizScores("8 7"), "8", "Tạm tính"));
        semesterTwo.add(buildGrade(user, "Khoa học tự nhiên", SchoolSemester.SEMESTER_2, null, semesterTwoOralScores(index, "8 7"), semesterTwoQuizScores("8 7"), "8", "Tạm tính"));
        semesterTwo.add(buildGrade(user, "Lịch sử và Địa lý", SchoolSemester.SEMESTER_2, null, semesterTwoOralScores(index, "7 7"), semesterTwoQuizScores("7 7"), "7", "Tạm tính"));
        semesterTwo.add(buildGrade(user, "Tin học", SchoolSemester.SEMESTER_2, null, semesterTwoOralScores(index, "8"), semesterTwoQuizScores("8 8"), "8", "Tạm tính"));
        semesterTwo.add(buildGrade(user, "GDCD", SchoolSemester.SEMESTER_2, null, semesterTwoOralScores(index, "7"), semesterTwoQuizScores("7 7"), "7", "Tạm tính"));
        semesterTwo.add(buildPassFailGrade(user, "Giáo dục thể chất", SchoolSemester.SEMESTER_2));

        gradeRepository.saveAll(semesterOne);
        gradeRepository.saveAll(semesterTwo);

        user.setGpa(calculateGpa(semesterOne));
        appUserRepository.save(user);
    }

    private String semesterTwoOralScores(int index, String value) {
        if (value == null || value.isBlank()) {
            return "";
        }
        String[] parts = value.trim().split("\\s+");
        if (index % 4 == 0 && parts.length > 0) {
            return parts[0];
        }
        return String.join(" ", parts);
    }

    private String semesterTwoQuizScores(String value) {
        if (value == null || value.isBlank()) {
            return "";
        }
        return value.trim().split("\\s+")[0];
    }

    private void seedNotes(AppUser user) {
        noteRepository.save(buildNote(user, "Toán - công thức", "Tóm tắt công thức cần nhớ...", "Ôn lại công thức và dạng bài tiêu biểu.", LocalDate.of(2026, 3, 1)));
        noteRepository.save(buildNote(user, "Ngữ văn - dàn ý", "Mở bài, thân bài, kết bài...", "Dàn ý cho bài văn kể chuyện và miêu tả.", LocalDate.of(2026, 2, 28)));
    }

    private void seedUpcomingClasses(AppUser user) {
        TimeSlot mathSlot = slotFor(user.getClassName(), 0);
        TimeSlot literatureSlot = slotFor(user.getClassName(), 1);
        TimeSlot scienceSlot = slotFor(user.getClassName(), 2);
        TimeSlot englishSlot = slotFor(user.getClassName(), 4);
        TimeSlot informaticsSlot = slotFor(user.getClassName(), 5);
        upcomingClassRepository.save(buildClass(user, "T2", 2, "Toán", "Phòng " + user.getClassName(), mathSlot.start(), "Thầy Toán"));
        upcomingClassRepository.save(buildClass(user, "T3", 3, "Tiếng Anh", "Phòng " + user.getClassName(), englishSlot.start(), "Cô Anh"));
    }

    private void seedTimetable(AppUser user) {
        LocalDate start = LocalDate.of(2026, 3, 2);
        TimeSlot mathSlot = slotFor(user.getClassName(), 0);
        TimeSlot literatureSlot = slotFor(user.getClassName(), 1);
        TimeSlot scienceSlot = slotFor(user.getClassName(), 2);
        TimeSlot englishSlot = slotFor(user.getClassName(), 4);
        TimeSlot informaticsSlot = slotFor(user.getClassName(), 5);
        for (int i = 0; i < 10; i++) {
            LocalDate date = start.plusDays(i);
            if (date.getDayOfWeek() == DayOfWeek.SATURDAY || date.getDayOfWeek() == DayOfWeek.SUNDAY) {
                continue;
            }
            scheduleItemRepository.save(buildSchedule(
                    user,
                    date,
                    "Toán",
                    user.getClassName(),
                    mathSlot.start(),
                    mathSlot.end(),
                    "Thầy Toán",
                    "#2563EB"
            ));
            scheduleItemRepository.save(buildSchedule(
                    user,
                    date,
                    "Ngữ văn",
                    user.getClassName(),
                    literatureSlot.start(),
                    literatureSlot.end(),
                    "Cô Văn",
                    "#7C3AED"
            ));
            scheduleItemRepository.save(buildSchedule(
                    user,
                    date,
                    "Khoa học tự nhiên",
                    user.getClassName(),
                    scienceSlot.start(),
                    scienceSlot.end(),
                    "Thầy KHTN",
                    "#059669"
            ));
            scheduleItemRepository.save(buildSchedule(
                    user,
                    date,
                    "Tiếng Anh",
                    user.getClassName(),
                    englishSlot.start(),
                    englishSlot.end(),
                    "Cô Anh",
                    "#F97316"
            ));
            scheduleItemRepository.save(buildSchedule(
                    user,
                    date,
                    "Tin học",
                    user.getClassName(),
                    informaticsSlot.start(),
                    informaticsSlot.end(),
                    "Cô Tin",
                    "#0EA5E9"
            ));
            if (date.getDayOfWeek() == DayOfWeek.FRIDAY) {
                scheduleItemRepository.save(buildSchedule(
                        user,
                        date,
                        "Sinh hoạt lớp",
                        user.getClassName(),
                        "11:00",
                        "11:45",
                        "GVCN " + user.getClassName(),
                        "#0F766E"
                ));
            }
        }
    }

    private void seedAlerts(AppUser user) {
        alertNoticeRepository.save(buildAlert(user, "Thông báo hệ thống", "Lịch học tuần này đã được cập nhật.", AlertType.INFO, Instant.now().minusSeconds(3600), false));
        alertNoticeRepository.save(buildAlert(user, "Học phí học kỳ 2", "Có thể thanh toán từ 26/01/2026 đến 01/05/2026.", AlertType.WARNING, Instant.now().minusSeconds(7200), false));
    }

    private void seedServiceRequests(AppUser user) {
        ServiceRequest support = new ServiceRequest();
        support.setUser(user);
        support.setTitle("Yêu cầu hỗ trợ tài khoản");
        support.setType("Hỗ trợ");
        support.setCategory(ServiceRequestCategory.SUPPORT);
        support.setDescription("Cần hỗ trợ cập nhật thông tin hồ sơ.");
        support.setStatus(ServiceRequestStatus.IN_PROGRESS);
        support.setHandlerNote("Đang kiểm tra dữ liệu.");
        support.setCreatedAt(Instant.now().minusSeconds(172800));
        support.setUpdatedAt(Instant.now().minusSeconds(86400));
        serviceRequestRepository.save(support);

        ServiceRequest exam = new ServiceRequest();
        exam.setUser(user);
        exam.setTitle("Xin phúc khảo");
        exam.setType("Khảo thí");
        exam.setCategory(ServiceRequestCategory.EXAM);
        exam.setDescription("Đề nghị kiểm tra lại điểm bài kiểm tra giữa kỳ.");
        exam.setStatus(ServiceRequestStatus.PENDING);
        exam.setHandlerNote("");
        exam.setCreatedAt(Instant.now().minusSeconds(259200));
        exam.setUpdatedAt(Instant.now().minusSeconds(259200));
        serviceRequestRepository.save(exam);
    }

    private void seedTuition(AppUser user, int index) {
        TuitionInvoice invoice = new TuitionInvoice();
        invoice.setUser(user);
        invoice.setTitle("Học phí học kỳ 2");
        invoice.setAmount(10_000);
        invoice.setAvailableFrom(LocalDate.of(2026, 1, 26));
        invoice.setDueDate(LocalDate.of(2026, 5, 1));
        if (index % 5 == 0) {
            invoice.setStatus(TuitionInvoiceStatus.PAID);
            invoice.setPaidAt(Instant.now().minusSeconds(86400));
            invoice.setPayOsOrderCode(202600000L + user.getId());
            invoice.setCheckoutUrl("https://pay.payos.vn/web/" + (202600000L + user.getId()));
            invoice.setQrCode("PAYOS|" + (202600000L + user.getId()) + "|10000");
        } else if (index % 3 == 0) {
            invoice.setStatus(TuitionInvoiceStatus.PENDING);
            invoice.setPayOsOrderCode(202600000L + user.getId());
            invoice.setCheckoutUrl("https://pay.payos.vn/web/" + (202600000L + user.getId()));
            invoice.setQrCode("PAYOS|" + (202600000L + user.getId()) + "|10000");
        } else {
            invoice.setStatus(TuitionInvoiceStatus.UNPAID);
        }
        tuitionInvoiceRepository.save(invoice);
    }

    private void seedTeacherAssignments(Map<String, AppUser> homeroomTeachers, Map<String, AppUser> subjectTeachers) {
        for (String className : homeroomTeachers.keySet()) {
            teacherAssignmentRepository.save(buildAssignment(
                    homeroomTeachers.get(className),
                    className,
                    "Sinh hoạt lớp tuần",
                    "Chủ nhiệm",
                    LocalDate.of(2026, 3, 8),
                    "Nộp báo cáo trực tuần.",
                    "bao-cao-tuan.pdf"
            ));
            teacherAssignmentRepository.save(buildAssignment(
                    subjectTeachers.get("Toán"),
                    className,
                    "Phiếu bài tập chương số hữu tỉ",
                    "Toán",
                    LocalDate.of(2026, 3, 10),
                    "Hoàn thành đầy đủ các câu trong phiếu.",
                    "toan-hk2.xlsx"
            ));
        }
    }

    private void seedTeacherDirectChat(AppUser examOfficer, AppUser teacher) {
        if (examOfficer == null || teacher == null) {
            return;
        }

        Conversation conversation = new Conversation();
        conversation.setGroupChat(false);
        conversation.setName("");
        conversation.setCreatedBy(examOfficer);
        conversation.setCreatedAt(Instant.now().minusSeconds(300));
        conversation.setUpdatedAt(Instant.now().minusSeconds(120));
        conversation = conversationRepository.save(conversation);

        ConversationMember officerMember = new ConversationMember();
        officerMember.setConversation(conversation);
        officerMember.setUser(examOfficer);
        officerMember.setJoinedAt(Instant.now().minusSeconds(300));
        officerMember.setLastReadAt(Instant.now());
        conversationMemberRepository.save(officerMember);

        ConversationMember teacherMember = new ConversationMember();
        teacherMember.setConversation(conversation);
        teacherMember.setUser(teacher);
        teacherMember.setJoinedAt(Instant.now().minusSeconds(300));
        teacherMember.setLastReadAt(Instant.EPOCH);
        conversationMemberRepository.save(teacherMember);

        ConversationMessage message = new ConversationMessage();
        message.setConversation(conversation);
        message.setSender(examOfficer);
        message.setText("Nhờ cô rà soát tình hình nộp học phí lớp 6A.");
        message.setSentAt(Instant.now().minusSeconds(120));
        conversationMessageRepository.save(message);
    }

    private double adjust(int index) {
        return ((index % 5) - 2) * 0.1;
    }

    private Homework buildHomework(AppUser user,
                                   String title,
                                   String subject,
                                   LocalDate dueDate,
                                   HomeworkStatus status,
                                   int submitted,
                                   int total) {
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

    private Grade buildGrade(AppUser user,
                             String subject,
                             SchoolSemester semester,
                             Double semesterScore,
                             String oralScores,
                             String quizScores,
                             String examScores,
                             String note) {
        Grade grade = new Grade();
        grade.setUser(user);
        grade.setSubject(subject);
        grade.setSemester(semester);
        grade.setLetter("");
        grade.setOralScores(oralScores);
        grade.setQuizScores(quizScores);
        grade.setExamScores(examScores);
        grade.setSemesterScore(semesterScore == null
                ? null
                : BigDecimal.valueOf(semesterScore).setScale(1, RoundingMode.HALF_UP));
        grade.setScore(calculateAverage(oralScores, quizScores, examScores, grade.getSemesterScore()));
        grade.setNote(note);
        return grade;
    }

    private Grade buildPassFailGrade(AppUser user, String subject, SchoolSemester semester) {
        Grade grade = new Grade();
        grade.setUser(user);
        grade.setSubject(subject);
        grade.setSemester(semester);
        grade.setLetter("");
        grade.setOralScores("");
        grade.setQuizScores("");
        grade.setExamScores("");
        if (semester == SchoolSemester.SEMESTER_1) {
            grade.setSemesterScore(BigDecimal.TEN);
            grade.setScore(BigDecimal.TEN);
            grade.setNote("Đạt");
        } else {
            grade.setSemesterScore(null);
            grade.setScore(BigDecimal.ZERO);
            grade.setNote("");
        }
        return grade;
    }

    private BigDecimal calculateAverage(String oralScores,
                                        String quizScores,
                                        String examScores,
                                        BigDecimal semesterScore) {
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

        if (weight == 0) {
            return BigDecimal.ZERO;
        }
        return total.divide(BigDecimal.valueOf(weight), 1, RoundingMode.HALF_UP);
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
            }
        }
        return scores;
    }

    private BigDecimal calculateGpa(List<Grade> grades) {
        BigDecimal total = BigDecimal.ZERO;
        int count = 0;
        for (Grade grade : grades) {
            if ("Đạt".equalsIgnoreCase(grade.getNote())) {
                continue;
            }
            total = total.add(grade.getScore());
            count++;
        }
        return count == 0
                ? BigDecimal.ZERO
                : total.divide(BigDecimal.valueOf(count), 1, RoundingMode.HALF_UP);
    }

    private Note buildNote(AppUser user,
                           String title,
                           String preview,
                           String content,
                           LocalDate noteDate) {
        Note note = new Note();
        note.setUser(user);
        note.setTitle(title);
        note.setPreview(preview);
        note.setContent(content);
        note.setNoteDate(noteDate);
        return note;
    }

    private UpcomingClass buildClass(AppUser user,
                                     String dayLabel,
                                     int dayNumber,
                                     String subject,
                                     String room,
                                     String startTime,
                                     String teacher) {
        UpcomingClass item = new UpcomingClass();
        item.setUser(user);
        item.setDayLabel(dayLabel);
        item.setDayNumber(dayNumber);
        item.setSubject(subject);
        item.setRoom(room);
        item.setStartTime(startTime);
        item.setTeacher(teacher);
        return item;
    }

    private ScheduleItem buildSchedule(AppUser user,
                                       LocalDate scheduleDate,
                                       String subject,
                                       String room,
                                       String startTime,
                                       String endTime,
                                       String teacher,
                                       String colorHex) {
        ScheduleItem item = new ScheduleItem();
        item.setUser(user);
        item.setDayOfWeekIndex(scheduleDate.getDayOfWeek().getValue() - 1);
        item.setDayShort(shortLabel(scheduleDate));
        item.setDayFull(fullLabel(scheduleDate));
        item.setDayOfMonth(scheduleDate.getDayOfMonth());
        item.setScheduleDate(scheduleDate);
        item.setWeekOfSemester(7);
        item.setSubject(subject);
        item.setRoom(room);
        item.setStartTime(startTime);
        item.setEndTime(endTime);
        item.setTeacher(teacher);
        item.setColorHex(colorHex);
        return item;
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

    private TimeSlot slotFor(String className, int offset) {
        List<TimeSlot> slots = List.of(
                new TimeSlot("08:00", "08:45"),
                new TimeSlot("09:00", "09:45"),
                new TimeSlot("10:00", "10:45"),
                new TimeSlot("13:25", "14:10"),
                new TimeSlot("14:20", "15:05"),
                new TimeSlot("15:15", "16:00"),
                new TimeSlot("16:10", "16:55"),
                new TimeSlot("17:05", "17:50")
        );

        int index = switch (className) {
            case "6A" -> 0;
            case "6B" -> 1;
            case "7A" -> 2;
            case "7B" -> 3;
            case "8A" -> 4;
            case "8B" -> 5;
            case "9A" -> 6;
            case "9B" -> 7;
            default -> 0;
        };

        return slots.get((index + offset) % slots.size());
    }

    private AlertNotice buildAlert(AppUser user,
                                   String title,
                                   String message,
                                   AlertType type,
                                   Instant createdAt,
                                   boolean read) {
        AlertNotice alert = new AlertNotice();
        alert.setUser(user);
        alert.setTitle(title);
        alert.setMessage(message);
        alert.setType(type);
        alert.setCreatedAt(createdAt);
        alert.setRead(read);
        return alert;
    }

    private TeacherAssignment buildAssignment(AppUser creator,
                                              String targetClass,
                                              String title,
                                              String subject,
                                              LocalDate dueDate,
                                              String note,
                                              String attachmentName) {
        TeacherAssignment assignment = new TeacherAssignment();
        assignment.setCreatedBy(creator);
        assignment.setTargetClass(targetClass);
        assignment.setTitle(title);
        assignment.setSubject(subject);
        assignment.setDueDate(dueDate);
        assignment.setNote(note);
        assignment.setAttachmentName(attachmentName);
        assignment.setCreatedAt(Instant.now().minusSeconds(86_400));
        return assignment;
    }

    private record TimeSlot(String start, String end) {
    }
}
