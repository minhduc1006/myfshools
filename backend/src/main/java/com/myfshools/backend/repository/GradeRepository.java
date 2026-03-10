package com.myfshools.backend.repository;

import com.myfshools.backend.domain.Grade;
import com.myfshools.backend.domain.SchoolSemester;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface GradeRepository extends JpaRepository<Grade, Long> {
    List<Grade> findByUserIdOrderBySubjectAsc(Long userId);
    List<Grade> findByUserIdAndSemesterOrderBySubjectAsc(Long userId, SchoolSemester semester);
    List<Grade> findByUserClassNameAndSemesterOrderByUserFullNameAscSubjectAsc(String className, SchoolSemester semester);
    List<Grade> findByUserClassNameAndSemesterAndSubjectOrderByUserFullNameAsc(String className, SchoolSemester semester, String subject);
    Optional<Grade> findByUserIdAndSubjectAndSemester(Long userId, String subject, SchoolSemester semester);
}
