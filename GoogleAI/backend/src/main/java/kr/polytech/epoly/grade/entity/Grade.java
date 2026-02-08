// grade/entity/Grade.java — 성적 엔티티
package kr.polytech.epoly.grade.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "grades")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Grade {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private Long courseId;

    private BigDecimal attendanceScore;
    private BigDecimal assignmentScore;
    private BigDecimal examScore;
    private BigDecimal totalScore;

    @Column(length = 5)
    private String letterGrade;

    @Builder.Default
    private Boolean passed = false;

    @Column(columnDefinition = "TEXT")
    private String feedback;

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
