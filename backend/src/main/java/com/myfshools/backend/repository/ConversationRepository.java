package com.myfshools.backend.repository;

import com.myfshools.backend.domain.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface ConversationRepository extends JpaRepository<Conversation, Long> {
    @Query("select m.conversation from ConversationMember m where m.user.id = :userId order by m.conversation.updatedAt desc")
    List<Conversation> findForUser(Long userId);
}
