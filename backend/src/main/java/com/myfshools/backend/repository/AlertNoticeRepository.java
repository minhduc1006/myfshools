package com.myfshools.backend.repository;

import com.myfshools.backend.domain.AlertNotice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AlertNoticeRepository extends JpaRepository<AlertNotice, Long> {
    List<AlertNotice> findByUserIdOrderByCreatedAtDesc(Long userId);
    long countByUserIdAndReadFalse(Long userId);
}
