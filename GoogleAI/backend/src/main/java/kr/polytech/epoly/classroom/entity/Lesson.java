// classroom/entity/Lesson.java — 학습 콘텐츠(차시) 엔티티
package kr.polytech.epoly.classroom.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "lessons")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Lesson {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long courseId;

    @Column(nullable = false)
    private Integer weekNo;

    @Column(nullable = false)
    private Integer orderNo;

    @Column(nullable = false, length = 200)
    private String title;

    /** VIDEO, DOCUMENT, QUIZ, ASSIGNMENT, LINK */
    @Column(nullable = false, length = 20)
    private String contentType;

    @Column(length = 500)
    private String contentUrl;

    private Integer durationMinutes;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    @Builder.Default
    private Boolean isRequired = true;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
