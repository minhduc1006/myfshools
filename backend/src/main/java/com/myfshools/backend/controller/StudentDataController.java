package com.myfshools.backend.controller;

import com.myfshools.backend.dto.*;
import com.myfshools.backend.service.StudentDataService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class StudentDataController {
    private final StudentDataService studentDataService;

    public StudentDataController(StudentDataService studentDataService) {
        this.studentDataService = studentDataService;
    }

    @GetMapping("/dashboard")
    public DashboardResponse dashboard() {
        return studentDataService.dashboard();
    }

    @GetMapping("/homework")
    public List<HomeworkDto> homeworks(@RequestParam(defaultValue = "all") String status) {
        return studentDataService.homeworks(status);
    }

    @GetMapping("/grades")
    public List<GradeDto> grades() {
        return studentDataService.grades();
    }

    @GetMapping("/notes")
    public List<NoteDto> notes() {
        return studentDataService.notes();
    }

    @PostMapping("/notes")
    public NoteDto createNote(@Valid @RequestBody CreateNoteRequest request) {
        return studentDataService.createNote(request);
    }

    @PutMapping("/notes/{noteId}")
    public NoteDto updateNote(@PathVariable Long noteId, @Valid @RequestBody CreateNoteRequest request) {
        return studentDataService.updateNote(noteId, request);
    }

    @DeleteMapping("/notes/{noteId}")
    public void deleteNote(@PathVariable Long noteId) {
        studentDataService.deleteNote(noteId);
    }

    @GetMapping("/timetable")
    public List<ScheduleItemDto> timetable() {
        return studentDataService.timetable();
    }

    @GetMapping("/chat/users")
    public List<UserSummary> chatUsers() {
        return studentDataService.chatUsers();
    }

    @GetMapping("/chat/threads")
    public List<ChatThreadDto> chatThreads() {
        return studentDataService.chatThreads();
    }

    @PostMapping("/chat/direct")
    public ChatThreadDto createDirectChat(@Valid @RequestBody CreateDirectChatRequest request) {
        return studentDataService.createDirectChat(request);
    }

    @PostMapping("/chat/groups")
    public ChatThreadDto createGroupChat(@Valid @RequestBody CreateGroupChatRequest request) {
        return studentDataService.createGroupChat(request);
    }

    @PostMapping("/chat/groups/{conversationId}/invite")
    public ChatThreadDto inviteToGroup(@PathVariable Long conversationId, @Valid @RequestBody InviteToGroupRequest request) {
        return studentDataService.inviteToGroup(conversationId, request);
    }

    @GetMapping("/chat/threads/{threadId}/messages")
    public List<ChatMessageDto> chatMessages(@PathVariable Long threadId) {
        return studentDataService.chatMessages(threadId);
    }

    @PostMapping("/chat/threads/{threadId}/messages")
    public ChatMessageDto sendChatMessage(@PathVariable Long threadId, @Valid @RequestBody SendChatMessageRequest request) {
        return studentDataService.sendChatMessage(threadId, request);
    }

    @GetMapping("/me/profile")
    public ProfileResponse profile() {
        return studentDataService.profile();
    }
}
