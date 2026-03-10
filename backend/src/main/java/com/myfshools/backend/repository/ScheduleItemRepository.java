package com.myfshools.backend.repository;

import com.myfshools.backend.domain.ScheduleItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ScheduleItemRepository extends JpaRepository<ScheduleItem, Long> {
    List<ScheduleItem> findByUserIdOrderByIdAsc(Long userId);

    List<ScheduleItem> findByUserIdOrderByScheduleDateAscStartTimeAsc(Long userId);

    List<ScheduleItem> findByTeacherOrderByScheduleDateAscStartTimeAsc(String teacher);
}
