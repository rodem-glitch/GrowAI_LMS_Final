// course/entity/Course.java — 강좌 엔티티
package kr.polytech.epoly.course.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "courses")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Course {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(length = 50)
    private String courseCode;

    @Column(length = 50)
    private String category;

    @Column(length = 50)
    private String campus;

    @Column(length = 100)
    private String department;

    private Long instructorId;

    @Column(length = 100)
    private String instructorName;

    private Integer credit;

    private Integer totalWeeks;

    private LocalDate startDate;
    private LocalDate endDate;

    @Column(length = 500)
    private String thumbnailUrl;

    @Column(nullable = false)
    @Builder.Default
    private String status = "ACTIVE";

    private Integer maxStudents;

    private Integer enrolledCount;

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
