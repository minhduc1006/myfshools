package com.myfshools.backend.repository;

import com.myfshools.backend.domain.ConversationMember;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ConversationMemberRepository extends JpaRepository<ConversationMember, Long> {
    List<ConversationMember> findByConversationId(Long conversationId);
    Optional<ConversationMember> findByConversationIdAndUserId(Long conversationId, Long userId);
    List<ConversationMember> findByUserIdOrderByConversationUpdatedAtDesc(Long userId);
}
