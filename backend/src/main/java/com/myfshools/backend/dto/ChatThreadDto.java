package com.myfshools.backend.dto;

public record ChatThreadDto(
        Long id,
        String name,
        String participantInitial,
        String lastMessage,
        String lastTime,
        int unreadCount,
        boolean group
) {
}
