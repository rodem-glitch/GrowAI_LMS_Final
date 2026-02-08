// ai/entity/AiChatHistory.java — AI 대화 이력 엔티티
package kr.polytech.epoly.ai.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "ai_chat_history")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class AiChatHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(length = 100)
    private String sessionId;

    /** USER, ASSISTANT */
    @Column(nullable = false, length = 20)
    private String role;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    private Long courseId;

    @Column(length = 50)
    private String model;

    private Integer tokenCount;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
