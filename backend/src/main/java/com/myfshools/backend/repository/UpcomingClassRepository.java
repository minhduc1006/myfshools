package com.myfshools.backend.repository;

import com.myfshools.backend.domain.UpcomingClass;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UpcomingClassRepository extends JpaRepository<UpcomingClass, Long> {
    List<UpcomingClass> findByUserIdOrderByIdAsc(Long userId);
}
