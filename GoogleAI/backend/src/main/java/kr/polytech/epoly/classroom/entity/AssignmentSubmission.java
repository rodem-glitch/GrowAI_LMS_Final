// classroom/entity/AssignmentSubmission.java — 과제 제출 엔티티
package kr.polytech.epoly.classroom.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "assignment_submissions")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class AssignmentSubmission {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long assignmentId;

    @Column(nullable = false)
    private Long userId;

    @Column(columnDefinition = "TEXT")
    private String content;

    @Column(length = 500)
    private String fileUrl;

    private Integer score;

    @Column(columnDefinition = "TEXT")
    private String feedback;

    /** SUBMITTED, GRADED, RETURNED */
    @Column(length = 20)
    @Builder.Default
    private String status = "SUBMITTED";

    @CreationTimestamp
    private LocalDateTime submittedAt;

    private LocalDateTime gradedAt;
}
