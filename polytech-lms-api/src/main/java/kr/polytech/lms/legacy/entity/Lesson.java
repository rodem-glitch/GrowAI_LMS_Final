// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/entity/Lesson.java
package kr.polytech.lms.legacy.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * 차시 엔티티
 * 레거시 LM_LESSON 테이블 매핑
 */
@Entity
@Table(name = "LM_LESSON")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Lesson {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "site_id", nullable = false)
    private Long siteId;

    @Column(name = "course_id")
    private Long courseId;

    @Column(name = "lesson_nm", length = 200)
    private String lessonNm;

    @Column(name = "lesson_no")
    private Integer lessonNo;

    @Column(name = "lesson_type", length = 20)
    private String lessonType;

    @Column(name = "status")
    private Integer status;

    @Column(name = "content_id")
    private Long contentId;

    @Column(name = "video_key", length = 100)
    private String videoKey;

    @Column(name = "play_time")
    private Integer playTime;

    @Column(name = "study_time")
    private Integer studyTime;

    @Column(name = "exam_id")
    private Long examId;

    @Column(name = "homework_id")
    private Long homeworkId;

    @Column(name = "survey_id")
    private Long surveyId;

    @Column(name = "sort")
    private Integer sort;

    @Column(name = "reg_date", length = 14)
    private String regDate;

    @Transient
    public boolean isActive() {
        return status != null && status == 1;
    }
}
