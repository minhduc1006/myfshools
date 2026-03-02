package com.myfshools.backend.domain;

import jakarta.persistence.*;

import java.time.LocalDate;

@Entity
@Table(name = "schedule_items")
public class ScheduleItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser user;

    @Column(nullable = false)
    private int dayOfWeekIndex;

    @Column(nullable = false, length = 8)
    private String dayShort;

    @Column(nullable = false, length = 20)
    private String dayFull;

    @Column(nullable = false)
    private int dayOfMonth;

    @Column(name = "schedule_date", nullable = true)
    private LocalDate scheduleDate;

    @Column(name = "week_of_semester", nullable = true)
    private Integer weekOfSemester;

    @Column(nullable = false)
    private String subject;

    @Column(nullable = false)
    private String room;

    @Column(nullable = false, length = 5)
    private String startTime;

    @Column(nullable = false, length = 5)
    private String endTime;

    @Column(nullable = false)
    private String teacher;

    @Column(nullable = false, length = 7)
    private String colorHex;

    public Long getId() { return id; }
    public AppUser getUser() { return user; }
    public void setUser(AppUser user) { this.user = user; }
    public int getDayOfWeekIndex() { return dayOfWeekIndex; }
    public void setDayOfWeekIndex(int dayOfWeekIndex) { this.dayOfWeekIndex = dayOfWeekIndex; }
    public String getDayShort() { return dayShort; }
    public void setDayShort(String dayShort) { this.dayShort = dayShort; }
    public String getDayFull() { return dayFull; }
    public void setDayFull(String dayFull) { this.dayFull = dayFull; }
    public int getDayOfMonth() { return dayOfMonth; }
    public void setDayOfMonth(int dayOfMonth) { this.dayOfMonth = dayOfMonth; }
    public LocalDate getScheduleDate() { return scheduleDate; }
    public void setScheduleDate(LocalDate scheduleDate) { this.scheduleDate = scheduleDate; }
    public Integer getWeekOfSemester() { return weekOfSemester; }
    public void setWeekOfSemester(Integer weekOfSemester) { this.weekOfSemester = weekOfSemester; }
    public String getSubject() { return subject; }
    public void setSubject(String subject) { this.subject = subject; }
    public String getRoom() { return room; }
    public void setRoom(String room) { this.room = room; }
    public String getStartTime() { return startTime; }
    public void setStartTime(String startTime) { this.startTime = startTime; }
    public String getEndTime() { return endTime; }
    public void setEndTime(String endTime) { this.endTime = endTime; }
    public String getTeacher() { return teacher; }
    public void setTeacher(String teacher) { this.teacher = teacher; }
    public String getColorHex() { return colorHex; }
    public void setColorHex(String colorHex) { this.colorHex = colorHex; }
}
