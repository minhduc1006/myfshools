package com.myfshools.backend.controller;

import com.myfshools.backend.dto.*;
import com.myfshools.backend.service.CampusOperationsService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class CampusOperationsController {
    private final CampusOperationsService campusOperationsService;

    public CampusOperationsController(CampusOperationsService campusOperationsService) {
        this.campusOperationsService = campusOperationsService;
    }

    @GetMapping("/alerts")
    public List<AlertDto> alerts() {
        return campusOperationsService.alerts();
    }

    @PostMapping("/exam/notices")
    public NoticeDeliveryResultDto createNotice(@Valid @RequestBody CreateNoticeRequest request) {
        return campusOperationsService.createNotice(request);
    }

    @PostMapping("/alerts/read-all")
    public void markAllAlertsRead() {
        campusOperationsService.markAllAlertsRead();
    }

    @GetMapping("/teacher/assignments")
    public List<TeacherAssignmentDto> teacherAssignments() {
        return campusOperationsService.teacherAssignments();
    }

    @PostMapping("/teacher/assignments")
    public TeacherAssignmentDto createTeacherAssignment(@Valid @RequestBody CreateTeacherAssignmentRequest request) {
        return campusOperationsService.createTeacherAssignment(request);
    }

    @GetMapping("/service-requests")
    public List<ServiceRequestDto> serviceRequests(@RequestParam(defaultValue = "mine") String category) {
        return campusOperationsService.serviceRequests(category);
    }

    @PostMapping("/service-requests")
    public ServiceRequestDto createServiceRequest(@Valid @RequestBody CreateServiceRequestRequest request) {
        return campusOperationsService.createServiceRequest(request);
    }

    @PostMapping("/service-requests/{requestId}/resolve")
    public ServiceRequestDto resolveServiceRequest(@PathVariable Long requestId, @RequestBody ResolveServiceRequestRequest request) {
        return campusOperationsService.resolveServiceRequest(requestId, request);
    }

    @GetMapping("/tuition/invoices")
    public List<TuitionInvoiceDto> tuitionInvoices() {
        return campusOperationsService.tuitionInvoices();
    }

    @PostMapping("/tuition/invoices/{invoiceId}/payos-link")
    public PayOsCheckoutDto createPayOsLink(@PathVariable Long invoiceId) {
        return campusOperationsService.createPayOsLink(invoiceId);
    }

    @PostMapping("/tuition/invoices/{invoiceId}/refresh-status")
    public TuitionInvoiceDto refreshPayOsStatus(@PathVariable Long invoiceId) {
        return campusOperationsService.refreshPayOsStatus(invoiceId);
    }

    @PostMapping("/tuition/invoices/{invoiceId}/confirm")
    public TuitionInvoiceDto confirmInvoicePaid(@PathVariable Long invoiceId) {
        return campusOperationsService.confirmInvoicePaid(invoiceId);
    }
}
