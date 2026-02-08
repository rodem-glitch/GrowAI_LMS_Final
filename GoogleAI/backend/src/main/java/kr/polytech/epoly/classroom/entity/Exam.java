// classroom/entity/Exam.java — 시험 엔티티
package kr.polytech.epoly.classroom.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "exams")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Exam {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long courseId;

    @Column(nullable = false, length = 200)
    private String title;

    /** MIDTERM, FINAL, QUIZ */
    @Column(length = 20)
    private String examType;

    private Integer timeLimitMinutes;

    private Integer totalScore;

    private LocalDateTime startTime;
    private LocalDateTime endTime;

    @Builder.Default
    private Boolean shuffleQuestions = false;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
