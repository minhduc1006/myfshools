package com.myfshools.backend.repository;

import com.myfshools.backend.domain.Homework;
import com.myfshools.backend.domain.HomeworkStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HomeworkRepository extends JpaRepository<Homework, Long> {
    List<Homework> findByUserIdOrderByDueDateAsc(Long userId);
    List<Homework> findByUserIdAndStatusOrderByDueDateAsc(Long userId, HomeworkStatus status);
}
