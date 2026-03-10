package com.myfshools.backend.controller;

import com.myfshools.backend.dto.StudentGradeRowDto;
import com.myfshools.backend.dto.TuitionClassSummaryDto;
import com.myfshools.backend.dto.UpdateStudentGradeRequest;
import com.myfshools.backend.dto.HomeworkClassReportDto;
import com.myfshools.backend.dto.HomeworkStudentStatusDto;
import com.myfshools.backend.service.TeacherAcademicService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api")
public class TeacherAcademicController {
    private final TeacherAcademicService teacherAcademicService;

    public TeacherAcademicController(TeacherAcademicService teacherAcademicService) {
        this.teacherAcademicService = teacherAcademicService;
    }

    @GetMapping("/teacher/classes/{className}/grades")
    public List<StudentGradeRowDto> classGrades(@PathVariable String className,
                                                @RequestParam(defaultValue = "1") String semester) {
        return teacherAcademicService.classGrades(className, semester);
    }

    @GetMapping("/teacher/subject-grades")
    public List<StudentGradeRowDto> subjectGrades(@RequestParam String className,
                                                  @RequestParam(defaultValue = "2") String semester) {
        return teacherAcademicService.subjectGrades(className, semester);
    }

    @PostMapping("/teacher/grades")
    public StudentGradeRowDto updateGrade(@Valid @RequestBody UpdateStudentGradeRequest request) {
        return teacherAcademicService.updateGrade(request);
    }

    @GetMapping("/teacher/homework-report/classes")
    public List<HomeworkClassReportDto> homeworkReportsByClass() {
        return teacherAcademicService.homeworkReportsByClass();
    }

    @GetMapping("/teacher/homework-report/classes/{className}")
    public List<HomeworkStudentStatusDto> homeworkDetailsByClass(@PathVariable String className) {
        return teacherAcademicService.homeworkDetailsByClass(className);
    }

    @PostMapping("/teacher/grades/import")
    public List<StudentGradeRowDto> importGrades(@RequestParam("file") MultipartFile file,
                                                 @RequestParam(defaultValue = "2") String semester) throws IOException {
        return teacherAcademicService.importGradesCsv(new String(file.getBytes()), semester);
    }

    @GetMapping("/exam/tuition-overview")
    public List<TuitionClassSummaryDto> tuitionOverview() {
        return teacherAcademicService.tuitionOverviewByClass();
    }

    @GetMapping("/exam/tuition-classes/{className}/students")
    public List<com.myfshools.backend.dto.TuitionStudentStatusDto> tuitionClassDetails(@PathVariable String className) {
        return teacherAcademicService.tuitionDetailsByClass(className);
    }
}
