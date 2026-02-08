// course/entity/Enrollment.java — 수강 등록 엔티티
package kr.polytech.epoly.course.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "enrollments", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"userId", "courseId"})
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Enrollment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private Long courseId;

    /** ENROLLED, COMPLETED, DROPPED */
    @Column(nullable = false, length = 20)
    @Builder.Default
    private String status = "ENROLLED";

    private Integer progressPercent;

    private LocalDateTime completedAt;

    @CreationTimestamp
    private LocalDateTime enrolledAt;
}
