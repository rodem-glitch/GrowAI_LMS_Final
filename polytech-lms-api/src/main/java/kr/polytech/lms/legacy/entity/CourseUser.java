// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/entity/CourseUser.java
package kr.polytech.lms.legacy.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * 수강생 엔티티
 * 레거시 LM_COURSE_USER 테이블 매핑
 */
@Entity
@Table(name = "LM_COURSE_USER")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CourseUser {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "site_id", nullable = false)
    private Long siteId;

    @Column(name = "course_id", nullable = false)
    private Long courseId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "status")
    private Integer status;

    @Column(name = "progress")
    private Integer progress;

    @Column(name = "exam_score")
    private Integer examScore;

    @Column(name = "homework_score")
    private Integer homeworkScore;

    @Column(name = "forum_score")
    private Integer forumScore;

    @Column(name = "etc_score")
    private Integer etcScore;

    @Column(name = "total_score")
    private Integer totalScore;

    @Column(name = "complete_yn", length = 1)
    private String completeYn;

    @Column(name = "complete_date", length = 14)
    private String completeDate;

    @Column(name = "start_date", length = 14)
    private String startDate;

    @Column(name = "end_date", length = 14)
    private String endDate;

    @Column(name = "reg_date", length = 14)
    private String regDate;

    @Transient
    public boolean isActive() {
        return status != null && status == 1;
    }

    @Transient
    public boolean isCompleted() {
        return "Y".equals(completeYn);
    }
}
