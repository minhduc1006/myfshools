package com.myfshools.backend.service;

import com.myfshools.backend.domain.AlertNotice;
import com.myfshools.backend.domain.AlertType;
import com.myfshools.backend.domain.AppUser;
import com.myfshools.backend.domain.ServiceRequest;
import com.myfshools.backend.domain.ServiceRequestCategory;
import com.myfshools.backend.domain.ServiceRequestStatus;
import com.myfshools.backend.domain.TeacherAssignment;
import com.myfshools.backend.domain.TuitionInvoice;
import com.myfshools.backend.domain.TuitionInvoiceStatus;
import com.myfshools.backend.domain.UserRole;
import com.myfshools.backend.dto.AlertDto;
import com.myfshools.backend.dto.CreateNoticeRequest;
import com.myfshools.backend.dto.CreateServiceRequestRequest;
import com.myfshools.backend.dto.CreateTeacherAssignmentRequest;
import com.myfshools.backend.dto.NoticeDeliveryResultDto;
import com.myfshools.backend.dto.PayOsCheckoutDto;
import com.myfshools.backend.dto.ResolveServiceRequestRequest;
import com.myfshools.backend.dto.ServiceRequestDto;
import com.myfshools.backend.dto.TeacherAssignmentDto;
import com.myfshools.backend.dto.TuitionInvoiceDto;
import com.myfshools.backend.repository.AlertNoticeRepository;
import com.myfshools.backend.repository.AppUserRepository;
import com.myfshools.backend.repository.ServiceRequestRepository;
import com.myfshools.backend.repository.TeacherAssignmentRepository;
import com.myfshools.backend.repository.TuitionInvoiceRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;

@Service
public class CampusOperationsService {
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter DATE_TIME_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private final CurrentUserService currentUserService;
    private final AppUserRepository appUserRepository;
    private final AlertNoticeRepository alertNoticeRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final ServiceRequestRepository serviceRequestRepository;
    private final TuitionInvoiceRepository tuitionInvoiceRepository;
    private final PayOsService payOsService;

    public CampusOperationsService(CurrentUserService currentUserService,
                                   AppUserRepository appUserRepository,
                                   AlertNoticeRepository alertNoticeRepository,
                                   TeacherAssignmentRepository teacherAssignmentRepository,
                                   ServiceRequestRepository serviceRequestRepository,
                                   TuitionInvoiceRepository tuitionInvoiceRepository,
                                   PayOsService payOsService) {
        this.currentUserService = currentUserService;
        this.appUserRepository = appUserRepository;
        this.alertNoticeRepository = alertNoticeRepository;
        this.teacherAssignmentRepository = teacherAssignmentRepository;
        this.serviceRequestRepository = serviceRequestRepository;
        this.tuitionInvoiceRepository = tuitionInvoiceRepository;
        this.payOsService = payOsService;
    }

    public List<AlertDto> alerts() {
        AppUser user = currentUserService.getRequiredUser();
        return alertNoticeRepository.findByUserIdOrderByCreatedAtDesc(user.getId()).stream()
                .map(this::toAlertDto)
                .toList();
    }

    @Transactional
    public NoticeDeliveryResultDto createNotice(CreateNoticeRequest request) {
        AppUser me = currentUserService.getRequiredUser();
        if (me.getRole() != UserRole.EXAM_OFFICER) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chỉ khảo thí mới được tạo thông báo");
        }

        String title = request.title() == null ? "" : request.title().trim();
        String message = request.message() == null ? "" : request.message().trim();
        if (title.isEmpty() || message.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vui lòng nhập tiêu đề và nội dung");
        }

        String target = request.target() == null ? "ALL" : request.target().trim().toUpperCase(Locale.ROOT);
        List<AppUser> recipients = new ArrayList<>();
        if ("CLASS".equals(target)) {
            String className = request.className() == null ? "" : request.className().trim();
            if (className.isEmpty()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vui lòng chọn lớp");
            }
            recipients.addAll(appUserRepository.findByClassNameOrderByFullNameAsc(className));
            recipients.addAll(appUserRepository.findByManagedClassOrderByFullNameAsc(className));
        } else {
            recipients.addAll(appUserRepository.findAllByOrderByClassNameAscFullNameAsc());
        }

        int delivered = 0;
        for (AppUser user : recipients) {
            if (user == null || user.getId() == null) continue;
            if (Objects.equals(user.getId(), me.getId())) continue;
            createAlert(user, title, message, AlertType.INFO);
            delivered++;
        }
        return new NoticeDeliveryResultDto(delivered);
    }

    @Transactional
    public void markAllAlertsRead() {
        AppUser user = currentUserService.getRequiredUser();
        List<AlertNotice> alerts = alertNoticeRepository.findByUserIdOrderByCreatedAtDesc(user.getId());
        for (AlertNotice alert : alerts) {
            alert.setRead(true);
        }
        alertNoticeRepository.saveAll(alerts);
    }

    public List<TeacherAssignmentDto> teacherAssignments() {
        AppUser user = currentUserService.getRequiredUser();
        requireTeacherRole(user);
        List<TeacherAssignment> merged = new ArrayList<>();
        merged.addAll(teacherAssignmentRepository.findByTargetClassOrderByCreatedAtDesc(user.getClassName()));
        for (TeacherAssignment assignment : teacherAssignmentRepository.findByCreatedByIdOrderByCreatedAtDesc(user.getId())) {
            if (merged.stream().noneMatch(item -> Objects.equals(item.getId(), assignment.getId()))) {
                merged.add(assignment);
            }
        }
        merged.sort((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt()));
        return merged.stream().map(this::toTeacherAssignmentDto).toList();
    }

    @Transactional
    public TeacherAssignmentDto createTeacherAssignment(CreateTeacherAssignmentRequest request) {
        AppUser user = currentUserService.getRequiredUser();
        requireTeacherRole(user);

        TeacherAssignment assignment = new TeacherAssignment();
        assignment.setCreatedBy(user);
        assignment.setTitle(request.title().trim());
        assignment.setSubject(request.subject().trim());
        assignment.setTargetClass(request.targetClass().trim());
        assignment.setDueDate(parseDate(request.dueDate()));
        assignment.setNote(safeText(request.note(), "Không có ghi chú"));
        assignment.setAttachmentName(safeText(request.attachmentName(), "khong-co-tep-dinh-kem"));
        assignment.setCreatedAt(Instant.now());
        assignment = teacherAssignmentRepository.save(assignment);

        List<AppUser> targets = appUserRepository.findByClassNameOrderByFullNameAsc(assignment.getTargetClass());
        for (AppUser target : targets) {
            createAlert(
                    target,
                    "Bài tập mới",
                    assignment.getSubject() + ": " + assignment.getTitle() + " - hạn " + assignment.getDueDate().format(DATE_FMT),
                    AlertType.SUCCESS
            );
        }

        return toTeacherAssignmentDto(assignment);
    }

    public List<ServiceRequestDto> serviceRequests(String category) {
        AppUser user = currentUserService.getRequiredUser();
        if (category == null || category.isBlank() || "mine".equalsIgnoreCase(category)) {
            return serviceRequestRepository.findByUserIdOrderByUpdatedAtDesc(user.getId()).stream()
                    .map(this::toServiceRequestDto)
                    .toList();
        }

        ServiceRequestCategory parsed = parseCategory(category);
        List<ServiceRequest> requests;
        if (parsed == ServiceRequestCategory.EXAM && isExamOfficer(user)) {
            requests = serviceRequestRepository.findByCategoryOrderByUpdatedAtDesc(parsed);
        } else {
            requests = serviceRequestRepository.findByUserIdAndCategoryOrderByUpdatedAtDesc(user.getId(), parsed);
        }

        return requests.stream()
                .map(this::toServiceRequestDto)
                .toList();
    }

    @Transactional
    public ServiceRequestDto createServiceRequest(CreateServiceRequestRequest request) {
        AppUser user = currentUserService.getRequiredUser();

        ServiceRequest item = new ServiceRequest();
        item.setUser(user);
        item.setTitle(request.title().trim());
        item.setType(request.type().trim());
        item.setCategory(parseCategory(request.category()));
        item.setDescription(request.description().trim());
        item.setStatus(ServiceRequestStatus.PENDING);
        item.setHandlerNote("");
        item.setCreatedAt(Instant.now());
        item.setUpdatedAt(Instant.now());
        item = serviceRequestRepository.save(item);

        createAlert(
                user,
                "Đã gửi yêu cầu",
                "Yêu cầu \"" + item.getTitle() + "\" đã được chuyển sang bộ phận xử lý.",
                AlertType.INFO
        );
        return toServiceRequestDto(item);
    }

    @Transactional
    public ServiceRequestDto resolveServiceRequest(Long requestId, ResolveServiceRequestRequest request) {
        AppUser user = currentUserService.getRequiredUser();
        requireExamOfficerRole(user);
        ServiceRequest item = serviceRequestRepository.findById(requestId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy yêu cầu"));

        item.setStatus(ServiceRequestStatus.RESOLVED);
        item.setHandlerNote(safeText(request.note(), "Đã tiếp nhận và xử lý."));
        item.setUpdatedAt(Instant.now());
        item = serviceRequestRepository.save(item);

        createAlert(
                item.getUser(),
                "Yêu cầu đã xử lý",
                item.getTitle() + " đã được cập nhật bởi bộ phận " + categoryLabel(item.getCategory()) + ".",
                AlertType.SUCCESS
        );
        return toServiceRequestDto(item);
    }

    public List<TuitionInvoiceDto> tuitionInvoices() {
        AppUser user = currentUserService.getRequiredUser();
        return tuitionInvoiceRepository.findByUserIdOrderByDueDateAsc(user.getId()).stream()
                .map(this::toTuitionInvoiceDto)
                .toList();
    }

    @Transactional
    public PayOsCheckoutDto createPayOsLink(Long invoiceId) {
        TuitionInvoice invoice = requireInvoice(invoiceId);
        LocalDate today = LocalDate.now();
        LocalDate availableFrom = invoice.getAvailableFrom() == null
                ? invoice.getDueDate()
                : invoice.getAvailableFrom();
        if (today.isBefore(availableFrom) || today.isAfter(invoice.getDueDate())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Hóa đơn chỉ được thanh toán từ "
                            + availableFrom.format(DATE_FMT)
                            + " đến "
                            + invoice.getDueDate().format(DATE_FMT)
            );
        }

        PayOsCheckoutDto checkout = payOsService.createPaymentLink(invoice);
        invoice.setStatus(TuitionInvoiceStatus.PENDING);
        invoice.setPayOsOrderCode(checkout.orderCode());
        invoice.setCheckoutUrl(checkout.checkoutUrl());
        invoice.setQrCode(checkout.qrCode());
        tuitionInvoiceRepository.save(invoice);

        createAlert(
                invoice.getUser(),
                "Khởi tạo thanh toán PayOS",
                "Đơn " + invoice.getTitle() + " đã được tạo liên kết thanh toán qua PayOS.",
                AlertType.INFO
        );
        return checkout;
    }

    @Transactional
    public TuitionInvoiceDto refreshPayOsStatus(Long invoiceId) {
        TuitionInvoice invoice = requireInvoice(invoiceId);
        PayOsCheckoutDto checkout = payOsService.getPaymentLinkInfo(invoice);

        invoice.setCheckoutUrl(checkout.checkoutUrl());
        invoice.setQrCode(checkout.qrCode());
        syncInvoiceStatus(invoice, checkout.status());
        invoice = tuitionInvoiceRepository.save(invoice);
        return toTuitionInvoiceDto(invoice);
    }

    @Transactional
    public TuitionInvoiceDto confirmInvoicePaid(Long invoiceId) {
        TuitionInvoice invoice = requireInvoice(invoiceId);
        invoice.setStatus(TuitionInvoiceStatus.PAID);
        if (invoice.getPaidAt() == null) {
            invoice.setPaidAt(Instant.now());
        }
        invoice = tuitionInvoiceRepository.save(invoice);
        createAlert(
                invoice.getUser(),
                "Thanh toán thành công",
                invoice.getTitle() + " đã được ghi nhận thanh toán.",
                AlertType.SUCCESS
        );
        return toTuitionInvoiceDto(invoice);
    }

    private TuitionInvoice requireInvoice(Long invoiceId) {
        AppUser user = currentUserService.getRequiredUser();
        return tuitionInvoiceRepository.findByIdAndUserId(invoiceId, user.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy hóa đơn"));
    }

    private void requireTeacherRole(AppUser user) {
        if (!isTeacher(user)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chá»©c nÄƒng nÃ y chá»‰ dÃ nh cho giÃ¡o viÃªn");
        }
    }

    private void requireExamOfficerRole(AppUser user) {
        if (!isExamOfficer(user)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chá»©c nÄƒng nÃ y chá»‰ dÃ nh cho bá»™ pháº­n kháº£o thÃ­");
        }
    }

    private boolean isTeacher(AppUser user) {
        return user.getRole() == UserRole.HOMEROOM_TEACHER || user.getRole() == UserRole.SUBJECT_TEACHER;
    }

    private boolean isExamOfficer(AppUser user) {
        return user.getRole() == UserRole.EXAM_OFFICER;
    }

    private void syncInvoiceStatus(TuitionInvoice invoice, String status) {
        String normalized = status == null ? "" : status.trim().toUpperCase(Locale.ROOT);
        if (normalized.contains("PAID")) {
            boolean newlyPaid = invoice.getStatus() != TuitionInvoiceStatus.PAID;
            invoice.setStatus(TuitionInvoiceStatus.PAID);
            if (invoice.getPaidAt() == null) {
                invoice.setPaidAt(Instant.now());
            }
            if (newlyPaid) {
                createAlert(
                        invoice.getUser(),
                        "Thanh toán thành công",
                        invoice.getTitle() + " đã được PayOS xác nhận thanh toán.",
                        AlertType.SUCCESS
                );
            }
        } else if (normalized.contains("CANCEL")) {
            invoice.setStatus(TuitionInvoiceStatus.CANCELLED);
        } else if (!normalized.isBlank()) {
            invoice.setStatus(TuitionInvoiceStatus.PENDING);
        }
    }

    private void createAlert(AppUser user, String title, String message, AlertType type) {
        AlertNotice alert = new AlertNotice();
        alert.setUser(user);
        alert.setTitle(title);
        alert.setMessage(message);
        alert.setType(type);
        alert.setRead(false);
        alert.setCreatedAt(Instant.now());
        alertNoticeRepository.save(alert);
    }

    private AlertDto toAlertDto(AlertNotice alert) {
        return new AlertDto(
                alert.getId(),
                alert.getTitle(),
                alert.getMessage(),
                alert.getType().name().toLowerCase(Locale.ROOT),
                formatInstant(alert.getCreatedAt()),
                alert.isRead()
        );
    }

    private TeacherAssignmentDto toTeacherAssignmentDto(TeacherAssignment assignment) {
        return new TeacherAssignmentDto(
                assignment.getId(),
                assignment.getTitle(),
                assignment.getSubject(),
                assignment.getTargetClass(),
                assignment.getDueDate().format(DATE_FMT),
                assignment.getNote(),
                assignment.getAttachmentName(),
                formatInstant(assignment.getCreatedAt()),
                assignment.getCreatedBy().getFullName()
        );
    }

    private ServiceRequestDto toServiceRequestDto(ServiceRequest item) {
        return new ServiceRequestDto(
                item.getId(),
                item.getTitle(),
                item.getType(),
                categoryLabel(item.getCategory()),
                item.getDescription(),
                statusLabel(item.getStatus()),
                item.getHandlerNote(),
                item.getUser().getFullName(),
                formatInstant(item.getCreatedAt()),
                formatInstant(item.getUpdatedAt())
        );
    }

    private TuitionInvoiceDto toTuitionInvoiceDto(TuitionInvoice invoice) {
        return new TuitionInvoiceDto(
                invoice.getId(),
                invoice.getTitle(),
                invoice.getAmount(),
                (invoice.getAvailableFrom() == null ? invoice.getDueDate() : invoice.getAvailableFrom()).format(DATE_FMT),
                invoice.getDueDate().format(DATE_FMT),
                invoiceStatusLabel(invoice.getStatus()),
                invoice.getPayOsOrderCode(),
                invoice.getCheckoutUrl(),
                invoice.getQrCode(),
                invoice.getPaidAt() == null ? "" : formatInstant(invoice.getPaidAt())
        );
    }

    private LocalDate parseDate(String value) {
        try {
            return LocalDate.parse(value.trim(), DATE_FMT);
        } catch (Exception ex) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Ngày không hợp lệ, cần đúng định dạng dd/MM/yyyy"
            );
        }
    }

    private ServiceRequestCategory parseCategory(String value) {
        String normalized = value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
        Map<String, ServiceRequestCategory> aliases = new LinkedHashMap<>();
        aliases.put("APPLICATION", ServiceRequestCategory.APPLICATION);
        aliases.put("DON", ServiceRequestCategory.APPLICATION);
        aliases.put("SUPPORT", ServiceRequestCategory.SUPPORT);
        aliases.put("HOTRO", ServiceRequestCategory.SUPPORT);
        aliases.put("HO_TRO", ServiceRequestCategory.SUPPORT);
        aliases.put("EXAM", ServiceRequestCategory.EXAM);
        aliases.put("KHAOTHI", ServiceRequestCategory.EXAM);
        aliases.put("KHAO_THI", ServiceRequestCategory.EXAM);

        ServiceRequestCategory parsed = aliases.get(
                normalized.replace(" ", "").replace("-", "_")
        );
        if (parsed != null) {
            return parsed;
        }

        try {
            return ServiceRequestCategory.valueOf(normalized);
        } catch (IllegalArgumentException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Loại yêu cầu không hợp lệ");
        }
    }

    private String safeText(String value, String fallback) {
        if (value == null || value.trim().isEmpty()) {
            return fallback;
        }
        return value.trim();
    }

    private String categoryLabel(ServiceRequestCategory category) {
        return switch (category) {
            case APPLICATION -> "Đơn từ";
            case SUPPORT -> "Hỗ trợ";
            case EXAM -> "Khảo thí";
        };
    }

    private String statusLabel(ServiceRequestStatus status) {
        return switch (status) {
            case PENDING -> "Chờ tiếp nhận";
            case IN_PROGRESS -> "Đang xử lý";
            case RESOLVED -> "Đã xử lý";
        };
    }

    private String invoiceStatusLabel(TuitionInvoiceStatus status) {
        return switch (status) {
            case UNPAID -> "Chưa thanh toán";
            case PENDING -> "Chờ xác nhận";
            case PAID -> "Đã thanh toán";
            case CANCELLED -> "Đã hủy";
        };
    }

    private String formatInstant(Instant instant) {
        if (instant == null) {
            return "";
        }
        return DATE_TIME_FMT.format(instant.atZone(ZoneId.systemDefault()));
    }
}
