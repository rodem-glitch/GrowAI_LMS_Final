// ai/entity/AiRecommendation.java — AI 추천 이력 엔티티
package kr.polytech.epoly.ai.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "ai_recommendations")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class AiRecommendation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private Long courseId;

    @Column(length = 50)
    private String recommendType;

    private Double score;

    @Column(columnDefinition = "TEXT")
    private String reason;

    @Builder.Default
    private Boolean clicked = false;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
