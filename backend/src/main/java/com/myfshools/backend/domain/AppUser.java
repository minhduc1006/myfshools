package com.myfshools.backend.domain;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "users")
public class AppUser {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 20)
    private String phone;

    @Column(nullable = false)
    private String passwordHash;

    @Column(nullable = false)
    private String fullName;

    @Column(name = "class_name", nullable = false)
    private String className;

    @ManyToOne
    @JoinColumn(name = "role_id")
    private Role role;

    @Column(name = "managed_class")
    private String managedClass;

    @Column(name = "subject_specialty")
    private String subjectSpecialty;

    @Column(nullable = false)
    private String term;

    @Column(nullable = false, precision = 3, scale = 2)
    private BigDecimal gpa;

    @Column(nullable = false, length = 2)
    private String avatarInitial;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();

    public Long getId() { return id; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getClassName() { return className; }
    public void setClassName(String className) { this.className = className; }
    public Role getRoleEntity() { return role; }
    public void setRoleEntity(Role role) { this.role = role; }

    public UserRole getRole() {
        if (role == null || role.getCode() == null) {
            return UserRole.STUDENT;
        }
        try {
            return UserRole.valueOf(role.getCode());
        } catch (IllegalArgumentException ex) {
            return UserRole.STUDENT;
        }
    }
    public String getManagedClass() { return managedClass; }
    public void setManagedClass(String managedClass) { this.managedClass = managedClass; }
    public String getSubjectSpecialty() { return subjectSpecialty; }
    public void setSubjectSpecialty(String subjectSpecialty) { this.subjectSpecialty = subjectSpecialty; }
    public String getTerm() { return term; }
    public void setTerm(String term) { this.term = term; }
    public BigDecimal getGpa() { return gpa; }
    public void setGpa(BigDecimal gpa) { this.gpa = gpa; }
    public String getAvatarInitial() { return avatarInitial; }
    public void setAvatarInitial(String avatarInitial) { this.avatarInitial = avatarInitial; }
    public Instant getCreatedAt() { return createdAt; }
}
