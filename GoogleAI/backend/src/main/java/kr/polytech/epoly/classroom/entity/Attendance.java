// classroom/entity/Attendance.java — 출석/학습진도 엔티티
package kr.polytech.epoly.classroom.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "attendances")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Attendance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private Long lessonId;

    @Column(nullable = false)
    private Long courseId;

    /** PRESENT, LATE, ABSENT */
    @Column(nullable = false, length = 20)
    @Builder.Default
    private String status = "ABSENT";

    private Integer watchedSeconds;

    private Integer totalSeconds;

    @Builder.Default
    private Integer progressPercent = 0;

    @Builder.Default
    private Boolean completed = false;

    private LocalDateTime startedAt;
    private LocalDateTime completedAt;

    @Column(length = 45)
    private String ipAddress;

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
