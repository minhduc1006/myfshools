package com.myfshools.backend.repository;

import com.myfshools.backend.domain.TuitionInvoice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TuitionInvoiceRepository extends JpaRepository<TuitionInvoice, Long> {
    List<TuitionInvoice> findByUserIdOrderByDueDateAsc(Long userId);
    Optional<TuitionInvoice> findByIdAndUserId(Long id, Long userId);
}
