package com.myfshools.backend.repository;

import com.myfshools.backend.domain.ConversationMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.Instant;
import java.util.List;

public interface ConversationMessageRepository extends JpaRepository<ConversationMessage, Long> {
    List<ConversationMessage> findByConversationIdOrderBySentAtAsc(Long conversationId);
    List<ConversationMessage> findTop1ByConversationIdOrderBySentAtDesc(Long conversationId);

    @Query("select count(m) from ConversationMessage m where m.conversation.id = :conversationId and m.sentAt > :since and m.sender.id <> :userId")
    long countUnread(Long conversationId, Instant since, Long userId);
}
