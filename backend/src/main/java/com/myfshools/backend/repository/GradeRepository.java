package com.myfshools.backend.repository;

import com.myfshools.backend.domain.Grade;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface GradeRepository extends JpaRepository<Grade, Long> {
    List<Grade> findByUserIdOrderBySubjectAsc(Long userId);
}
