package com.myfshools.backend.repository;

import com.myfshools.backend.domain.ServiceRequest;
import com.myfshools.backend.domain.ServiceRequestCategory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ServiceRequestRepository extends JpaRepository<ServiceRequest, Long> {
    List<ServiceRequest> findByUserIdOrderByUpdatedAtDesc(Long userId);
    List<ServiceRequest> findByCategoryOrderByUpdatedAtDesc(ServiceRequestCategory category);
    List<ServiceRequest> findByUserIdAndCategoryOrderByUpdatedAtDesc(Long userId, ServiceRequestCategory category);
    Optional<ServiceRequest> findByIdAndUserId(Long id, Long userId);
}
