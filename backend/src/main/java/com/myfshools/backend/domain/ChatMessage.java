package com.myfshools.backend.domain;

import jakarta.persistence.*;

import java.time.Instant;

@Entity
@Table(name = "chat_messages")
public class ChatMessage {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "thread_id", nullable = false)
    private ChatThread thread;

    @Column(nullable = false, length = 3000)
    private String text;

    @Column(nullable = false)
    private boolean fromMe;

    @Column(nullable = false)
    private Instant sentAt = Instant.now();

    public Long getId() { return id; }
    public ChatThread getThread() { return thread; }
    public void setThread(ChatThread thread) { this.thread = thread; }
    public String getText() { return text; }
    public void setText(String text) { this.text = text; }
    public boolean isFromMe() { return fromMe; }
    public void setFromMe(boolean fromMe) { this.fromMe = fromMe; }
    public Instant getSentAt() { return sentAt; }
    public void setSentAt(Instant sentAt) { this.sentAt = sentAt; }
}
