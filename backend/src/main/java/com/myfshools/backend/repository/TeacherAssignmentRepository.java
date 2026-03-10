package com.myfshools.backend.repository;

import com.myfshools.backend.domain.TeacherAssignment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TeacherAssignmentRepository extends JpaRepository<TeacherAssignment, Long> {
    List<TeacherAssignment> findByTargetClassOrderByCreatedAtDesc(String targetClass);
    List<TeacherAssignment> findByCreatedByIdOrderByCreatedAtDesc(Long createdById);
}
