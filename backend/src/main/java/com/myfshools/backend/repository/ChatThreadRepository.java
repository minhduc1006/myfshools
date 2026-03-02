package com.myfshools.backend.repository;

import com.myfshools.backend.domain.ChatThread;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ChatThreadRepository extends JpaRepository<ChatThread, Long> {
    List<ChatThread> findByUserIdOrderByUpdatedAtDesc(Long userId);
    Optional<ChatThread> findByIdAndUserId(Long id, Long userId);
}
