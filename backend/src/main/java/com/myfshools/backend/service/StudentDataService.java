package com.myfshools.backend.service;

import com.myfshools.backend.domain.*;
import com.myfshools.backend.dto.*;
import com.myfshools.backend.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
public class StudentDataService {
    private static final DateTimeFormatter DD_MM_YYYY = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter DD_MM = DateTimeFormatter.ofPattern("dd/MM");
    private static final DateTimeFormatter HH_MM = DateTimeFormatter.ofPattern("HH:mm");

    private final CurrentUserService currentUserService;
    private final AppUserRepository appUserRepository;
    private final HomeworkRepository homeworkRepository;
    private final GradeRepository gradeRepository;
    private final NoteRepository noteRepository;
    private final UpcomingClassRepository upcomingClassRepository;
    private final ScheduleItemRepository scheduleItemRepository;
    private final ConversationRepository conversationRepository;
    private final ConversationMemberRepository conversationMemberRepository;
    private final ConversationMessageRepository conversationMessageRepository;

    public StudentDataService(CurrentUserService currentUserService,
                              AppUserRepository appUserRepository,
                              HomeworkRepository homeworkRepository,
                              GradeRepository gradeRepository,
                              NoteRepository noteRepository,
                              UpcomingClassRepository upcomingClassRepository,
                              ScheduleItemRepository scheduleItemRepository,
                              ConversationRepository conversationRepository,
                              ConversationMemberRepository conversationMemberRepository,
                              ConversationMessageRepository conversationMessageRepository) {
        this.currentUserService = currentUserService;
        this.appUserRepository = appUserRepository;
        this.homeworkRepository = homeworkRepository;
        this.gradeRepository = gradeRepository;
        this.noteRepository = noteRepository;
        this.upcomingClassRepository = upcomingClassRepository;
        this.scheduleItemRepository = scheduleItemRepository;
        this.conversationRepository = conversationRepository;
        this.conversationMemberRepository = conversationMemberRepository;
        this.conversationMessageRepository = conversationMessageRepository;
    }

    public DashboardResponse dashboard() {
        AppUser user = currentUserService.getRequiredUser();
        List<UpcomingClassDto> upcoming = upcomingClassRepository.findByUserIdOrderByIdAsc(user.getId()).stream()
                .map(this::toUpcoming)
                .toList();

        return new DashboardResponse(user.getFullName(), user.getClassName(), user.getTerm(), user.getGpa(), upcoming);
    }

    public List<HomeworkDto> homeworks(String status) {
        AppUser user = currentUserService.getRequiredUser();
        List<Homework> list;
        if (status == null || status.equalsIgnoreCase("all")) {
            list = homeworkRepository.findByUserIdOrderByDueDateAsc(user.getId());
        } else {
            HomeworkStatus parsed;
            try {
                parsed = HomeworkStatus.valueOf(status.toUpperCase());
            } catch (IllegalArgumentException ex) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Trạng thái không hợp lệ");
            }
            list = homeworkRepository.findByUserIdAndStatusOrderByDueDateAsc(user.getId(), parsed);
        }
        return list.stream().map(this::toHomework).toList();
    }

    public List<GradeDto> grades(String semester) {
        AppUser user = currentUserService.getRequiredUser();
        SchoolSemester parsed = parseSemester(semester);
        return gradeRepository.findByUserIdAndSemesterOrderBySubjectAsc(user.getId(), parsed).stream().map(this::toGrade).toList();
    }

    public List<NoteDto> notes() {
        AppUser user = currentUserService.getRequiredUser();
        return noteRepository.findByUserIdOrderByNoteDateDescIdDesc(user.getId()).stream().map(this::toNote).toList();
    }

    public NoteDto createNote(CreateNoteRequest request) {
        AppUser user = currentUserService.getRequiredUser();
        Note note = new Note();
        note.setUser(user);
        note.setTitle(request.title().trim());
        note.setContent(request.content().trim());
        note.setPreview(buildPreview(request.content()));
        note.setNoteDate(LocalDate.now());
        return toNote(noteRepository.save(note));
    }

    public NoteDto updateNote(Long noteId, CreateNoteRequest request) {
        AppUser user = currentUserService.getRequiredUser();
        Note note = noteRepository.findByIdAndUserId(noteId, user.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy ghi chú"));
        note.setTitle(request.title().trim());
        note.setContent(request.content().trim());
        note.setPreview(buildPreview(request.content()));
        return toNote(noteRepository.save(note));
    }

    public void deleteNote(Long noteId) {
        AppUser user = currentUserService.getRequiredUser();
        Note note = noteRepository.findByIdAndUserId(noteId, user.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy ghi chú"));
        noteRepository.delete(note);
    }

    public List<ScheduleItemDto> timetable() {
        AppUser user = currentUserService.getRequiredUser();
        List<ScheduleItem> items;
        if (canViewTeachingTimetable(user)) {
            items = deduplicateTeachingSchedule(
                    scheduleItemRepository.findByTeacherOrderByScheduleDateAscStartTimeAsc(user.getFullName())
            );
        } else {
            items = scheduleItemRepository.findByUserIdOrderByScheduleDateAscStartTimeAsc(user.getId());
        }

        return items.stream()
                .map(this::toSchedule)
                .toList();
    }

    public List<UserSummary> chatUsers() {
        AppUser currentUser = currentUserService.getRequiredUser();
        String scopeClass = chatScopeClass(currentUser);
        return appUserRepository.findAllByOrderByClassNameAscFullNameAsc().stream()
                .filter(user -> !Objects.equals(user.getId(), currentUser.getId()))
                .filter(user -> scopeClass == null || Objects.equals(scopeClass, user.getClassName()))
                .map(user -> new UserSummary(
                        user.getId(),
                        user.getPhone(),
                        user.getFullName(),
                        user.getClassName(),
                        user.getRole() == null ? "STUDENT" : user.getRole().name(),
                        user.getManagedClass(),
                        user.getSubjectSpecialty(),
                        user.getTerm(),
                        user.getGpa(),
                        user.getAvatarInitial()
                ))
                .toList();
    }

    public List<ChatThreadDto> chatThreads() {
        AppUser user = currentUserService.getRequiredUser();
        List<ConversationMember> memberships = conversationMemberRepository.findByUserIdOrderByConversationUpdatedAtDesc(user.getId());
        return memberships.stream().map(m -> toThread(m.getConversation(), user)).toList();
    }

    public List<ChatMessageDto> chatMessages(Long conversationId) {
        AppUser user = currentUserService.getRequiredUser();
        ConversationMember membership = requireMembership(conversationId, user.getId());
        membership.setLastReadAt(Instant.now());
        conversationMemberRepository.save(membership);

        return conversationMessageRepository.findByConversationIdOrderBySentAtAsc(conversationId).stream()
                .map(msg -> toMessage(msg, user.getId()))
                .toList();
    }

    public ChatMessageDto sendChatMessage(Long conversationId, SendChatMessageRequest request) {
        AppUser user = currentUserService.getRequiredUser();
        requireMembership(conversationId, user.getId());

        Conversation conversation = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Conversation not found"));

        ConversationMessage msg = new ConversationMessage();
        msg.setConversation(conversation);
        msg.setSender(user);
        msg.setText(request.text().trim());
        msg = conversationMessageRepository.save(msg);

        conversation.setUpdatedAt(msg.getSentAt());
        conversationRepository.save(conversation);

        return toMessage(msg, user.getId());
    }

    public ChatThreadDto createDirectChat(CreateDirectChatRequest request) {
        AppUser me = currentUserService.getRequiredUser();
        String phone = request.phone() == null ? "" : request.phone().trim();
        if (phone.isEmpty()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vui lòng nhập số điện thoại");

        AppUser other = appUserRepository.findByPhone(phone)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy người dùng"));

        ensureChatTargetAllowed(me, other);

        if (Objects.equals(other.getId(), me.getId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Không thể chat với chính bạn");
        }

        List<ConversationMember> mine = conversationMemberRepository.findByUserIdOrderByConversationUpdatedAtDesc(me.getId());
        for (ConversationMember mem : mine) {
            Conversation c = mem.getConversation();
            if (!c.isGroupChat()) {
                List<ConversationMember> members = conversationMemberRepository.findByConversationId(c.getId());
                if (members.size() == 2 && members.stream().anyMatch(m -> Objects.equals(m.getUser().getId(), other.getId()))) {
                    return toThread(c, me);
                }
            }
        }

        Conversation c = new Conversation();
        c.setGroupChat(false);
        c.setName("");
        c.setCreatedBy(me);
        c.setCreatedAt(Instant.now());
        c.setUpdatedAt(Instant.now());
        c = conversationRepository.save(c);

        ConversationMember m1 = new ConversationMember();
        m1.setConversation(c);
        m1.setUser(me);
        m1.setJoinedAt(Instant.now());
        m1.setLastReadAt(Instant.now());

        ConversationMember m2 = new ConversationMember();
        m2.setConversation(c);
        m2.setUser(other);
        m2.setJoinedAt(Instant.now());
        m2.setLastReadAt(Instant.EPOCH);

        conversationMemberRepository.save(m1);
        conversationMemberRepository.save(m2);

        return toThread(c, me);
    }

    public ChatThreadDto createGroupChat(CreateGroupChatRequest request) {
        AppUser me = currentUserService.getRequiredUser();
        String name = request.name() == null ? "" : request.name().trim();
        if (name.isEmpty()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vui lòng nhập tên nhóm");

        Set<String> phones = new LinkedHashSet<>();
        if (request.memberPhones() != null) {
            for (String p : request.memberPhones()) {
                if (p != null && !p.trim().isEmpty()) phones.add(p.trim());
            }
        }

        Conversation c = new Conversation();
        c.setGroupChat(true);
        c.setName(name);
        c.setCreatedBy(me);
        c.setCreatedAt(Instant.now());
        c.setUpdatedAt(Instant.now());
        c = conversationRepository.save(c);

        List<AppUser> members = new ArrayList<>();
        members.add(me);
        for (String phone : phones) {
            appUserRepository.findByPhone(phone).ifPresent(u -> {
                ensureChatTargetAllowed(me, u);
                if (!Objects.equals(u.getId(), me.getId()) && members.stream().noneMatch(m -> Objects.equals(m.getId(), u.getId()))) {
                    members.add(u);
                }
            });
        }

        Instant now = Instant.now();
        for (AppUser u : members) {
            ConversationMember m = new ConversationMember();
            m.setConversation(c);
            m.setUser(u);
            m.setJoinedAt(now);
            m.setLastReadAt(Objects.equals(u.getId(), me.getId()) ? now : Instant.EPOCH);
            conversationMemberRepository.save(m);
        }

        return toThread(c, me);
    }

    public ChatThreadDto inviteToGroup(Long conversationId, InviteToGroupRequest request) {
        AppUser me = currentUserService.getRequiredUser();
        Conversation conversation = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy cuộc trò chuyện"));

        if (!conversation.isGroupChat()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Chỉ có thể mời thành viên vào nhóm");
        }

        requireMembership(conversationId, me.getId());

        String phone = request.phone() == null ? "" : request.phone().trim();
        if (phone.isEmpty()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vui lòng nhập số điện thoại");

        AppUser target = appUserRepository.findByPhone(phone)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy người dùng"));

        ensureChatTargetAllowed(me, target);

        boolean exists = conversationMemberRepository.findByConversationId(conversationId).stream()
                .anyMatch(m -> Objects.equals(m.getUser().getId(), target.getId()));

        if (!exists) {
            ConversationMember m = new ConversationMember();
            m.setConversation(conversation);
            m.setUser(target);
            m.setJoinedAt(Instant.now());
            m.setLastReadAt(Instant.EPOCH);
            conversationMemberRepository.save(m);

            conversation.setUpdatedAt(Instant.now());
            conversationRepository.save(conversation);
        }

        return toThread(conversation, me);
    }

    public ProfileResponse profile() {
        AppUser user = currentUserService.getRequiredUser();
        return new ProfileResponse(
                user.getId(),
                user.getPhone(),
                user.getFullName(),
                user.getClassName(),
                user.getRole() == null ? "STUDENT" : user.getRole().name(),
                user.getManagedClass(),
                user.getSubjectSpecialty(),
                user.getTerm(),
                user.getGpa(),
                user.getAvatarInitial()
        );
    }

    private ConversationMember requireMembership(Long conversationId, Long userId) {
        return conversationMemberRepository.findByConversationIdAndUserId(conversationId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không thuộc cuộc trò chuyện này"));
    }

    private boolean canViewTeachingTimetable(AppUser user) {
        return user.getRole() == UserRole.HOMEROOM_TEACHER || user.getRole() == UserRole.SUBJECT_TEACHER;
    }

    private String chatScopeClass(AppUser user) {
        if (user.getRole() == UserRole.HOMEROOM_TEACHER
                && user.getManagedClass() != null
                && !user.getManagedClass().isBlank()) {
            return user.getManagedClass();
        }
        if (user.getRole() == UserRole.STUDENT
                && user.getClassName() != null
                && !user.getClassName().isBlank()) {
            return user.getClassName();
        }
        return null;
    }

    private void ensureChatTargetAllowed(AppUser me, AppUser other) {
        String scopeClass = chatScopeClass(me);
        if (scopeClass != null && !Objects.equals(scopeClass, other.getClassName())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chi duoc chat voi nguoi dung trong cung lop");
        }
    }

    private List<ScheduleItem> deduplicateTeachingSchedule(List<ScheduleItem> items) {
        Map<String, ScheduleItem> unique = new LinkedHashMap<>();
        for (ScheduleItem item : items) {
            String key = String.join("|",
                    item.getScheduleDate() == null ? "" : item.getScheduleDate().toString(),
                    item.getStartTime() == null ? "" : item.getStartTime(),
                    item.getEndTime() == null ? "" : item.getEndTime(),
                    item.getSubject() == null ? "" : item.getSubject(),
                    item.getRoom() == null ? "" : item.getRoom(),
                    item.getTeacher() == null ? "" : item.getTeacher()
            );
            unique.putIfAbsent(key, item);
        }
        return new ArrayList<>(unique.values());
    }

    private HomeworkDto toHomework(Homework hw) {
        return new HomeworkDto(hw.getId(), hw.getTitle(), hw.getSubject(), hw.getDueDate().format(DD_MM_YYYY), hw.getStatus().name().toLowerCase(), hw.getProgressSubmitted() + "/" + hw.getProgressTotal());
    }

    private GradeDto toGrade(Grade g) {
        return new GradeDto(
                g.getId(),
                g.getSubject(),
                semesterLabel(g.getSemester()),
                g.getLetter(),
                g.getOralScores(),
                g.getQuizScores(),
                g.getExamScores(),
                g.getSemesterScore(),
                g.getScore(),
                g.getNote()
        );
    }

    private NoteDto toNote(Note note) {
        return new NoteDto(note.getId(), note.getTitle(), note.getPreview(), note.getContent(), note.getNoteDate().format(DD_MM));
    }

    private UpcomingClassDto toUpcoming(UpcomingClass c) {
        return new UpcomingClassDto(c.getId(), c.getDayLabel(), c.getDayNumber(), c.getSubject(), c.getRoom(), c.getStartTime(), c.getTeacher());
    }

    private ScheduleItemDto toSchedule(ScheduleItem s) {
        LocalDate scheduleDate = s.getScheduleDate() != null ? s.getScheduleDate() : LocalDate.now();
        int weekOfSemester = s.getWeekOfSemester() != null ? s.getWeekOfSemester() : 0;

        return new ScheduleItemDto(
                s.getId(),
                s.getDayOfWeekIndex(),
                s.getDayShort(),
                s.getDayFull(),
                s.getDayOfMonth(),
                scheduleDate.toString(),
                weekOfSemester,
                s.getSubject(),
                s.getRoom(),
                s.getStartTime(),
                s.getEndTime(),
                s.getTeacher(),
                s.getColorHex()
        );
    }

    private ChatThreadDto toThread(Conversation conversation, AppUser viewer) {
        List<ConversationMember> members = conversationMemberRepository.findByConversationId(conversation.getId());

        String name;
        String initial;
        if (conversation.isGroupChat()) {
            name = conversation.getName();
            initial = name.isEmpty() ? "G" : name.substring(0, 1).toUpperCase();
        } else {
            ConversationMember other = members.stream().filter(m -> !Objects.equals(m.getUser().getId(), viewer.getId())).findFirst().orElse(null);
            if (other == null) {
                name = "Direct Chat";
                initial = "D";
            } else {
                name = other.getUser().getFullName();
                initial = name.isEmpty() ? "U" : name.substring(0, 1).toUpperCase();
            }
        }

        String lastMessage = "";
        String lastTime = "";
        List<ConversationMessage> last = conversationMessageRepository.findTop1ByConversationIdOrderBySentAtDesc(conversation.getId());
        if (!last.isEmpty()) {
            ConversationMessage msg = last.get(0);
            lastMessage = msg.getText();
            lastTime = HH_MM.format(msg.getSentAt().atZone(ZoneId.systemDefault()));
        }

        Instant lastReadAt = members.stream()
                .filter(m -> Objects.equals(m.getUser().getId(), viewer.getId()))
                .map(ConversationMember::getLastReadAt)
                .findFirst()
                .orElse(Instant.EPOCH);

        int unread = (int) conversationMessageRepository.countUnread(conversation.getId(), lastReadAt, viewer.getId());

        return new ChatThreadDto(conversation.getId(), name, initial, lastMessage, lastTime, unread, conversation.isGroupChat());
    }

    private ChatMessageDto toMessage(ConversationMessage msg, Long viewerId) {
        return new ChatMessageDto(msg.getId(), Objects.equals(msg.getSender().getId(), viewerId), msg.getText(), HH_MM.format(msg.getSentAt().atZone(ZoneId.systemDefault())));
    }

    private String buildPreview(String content) {
        String c = content.trim();
        return c.length() <= 80 ? c : c.substring(0, 77) + "...";
    }

    private SchoolSemester parseSemester(String semester) {
        if (semester == null || semester.isBlank() || "1".equals(semester.trim()) || "hk1".equalsIgnoreCase(semester.trim())) {
            return SchoolSemester.SEMESTER_1;
        }
        if ("2".equals(semester.trim()) || "hk2".equalsIgnoreCase(semester.trim())) {
            return SchoolSemester.SEMESTER_2;
        }
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Hoc ky khong hop le");
    }

    private String semesterLabel(SchoolSemester semester) {
        return semester == SchoolSemester.SEMESTER_2 ? "2" : "1";
    }
}
