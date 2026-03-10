package com.myfshools.backend.repository;

import com.myfshools.backend.domain.AppUser;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AppUserRepository extends JpaRepository<AppUser, Long> {
    Optional<AppUser> findByPhone(String phone);
    List<AppUser> findAllByOrderByClassNameAscFullNameAsc();
    List<AppUser> findByClassNameOrderByFullNameAsc(String className);
    List<AppUser> findByManagedClassOrderByFullNameAsc(String managedClass);
}
