package com.myfshools.backend.repository;

import com.myfshools.backend.domain.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {
    List<ChatMessage> findByThreadIdOrderBySentAtAsc(Long threadId);
    List<ChatMessage> findTop1ByThreadIdOrderBySentAtDesc(Long threadId);
}
