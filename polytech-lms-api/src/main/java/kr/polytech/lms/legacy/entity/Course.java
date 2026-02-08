// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/entity/Course.java
package kr.polytech.lms.legacy.entity;

import jakarta.persistence.*;
import lombok.*;
import kr.polytech.lms.legacy.enums.CourseStatus;
import kr.polytech.lms.legacy.enums.CourseType;
import kr.polytech.lms.legacy.enums.OnOffType;

/**
 * 과정 엔티티
 * 레거시 LM_COURSE 테이블 매핑
 */
@Entity
@Table(name = "LM_COURSE")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Course {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "site_id", nullable = false)
    private Long siteId;

    @Column(name = "course_nm", length = 200)
    private String courseNm;

    @Column(name = "course_type", length = 1)
    private String courseType;

    @Column(name = "onoff_type", length = 1)
    private String onoffType;

    @Column(name = "status")
    private Integer status;

    @Column(name = "display_yn", length = 1)
    private String displayYn;

    @Column(name = "sale_yn", length = 1)
    private String saleYn;

    @Column(name = "taxfree_yn", length = 1)
    private String taxfreeYn;

    @Column(name = "year")
    private Integer year;

    @Column(name = "step")
    private Integer step;

    @Column(name = "request_sdate", length = 14)
    private String requestSdate;

    @Column(name = "request_edate", length = 14)
    private String requestEdate;

    @Column(name = "study_sdate", length = 14)
    private String studySdate;

    @Column(name = "study_edate", length = 14)
    private String studyEdate;

    @Column(name = "lesson_day")
    private Integer lessonDay;

    @Column(name = "close_yn", length = 1)
    private String closeYn;

    @Column(name = "manager_id")
    private Long managerId;

    @Column(name = "course_file", length = 200)
    private String courseFile;

    @Column(name = "sort")
    private Integer sort;

    @Column(name = "allsort")
    private Integer allsort;

    @Column(name = "recomm_yn", length = 1)
    private String recommYn;

    @Column(name = "reg_date", length = 14)
    private String regDate;

    // Enum 변환 메서드
    @Transient
    public CourseStatus getCourseStatusEnum() {
        return CourseStatus.fromCode(String.valueOf(status));
    }

    @Transient
    public CourseType getCourseTypeEnum() {
        return CourseType.fromCode(courseType);
    }

    @Transient
    public OnOffType getOnOffTypeEnum() {
        return OnOffType.fromCode(onoffType);
    }

    @Transient
    public boolean isActive() {
        return status != null && status == 1;
    }

    @Transient
    public boolean isDisplayed() {
        return "Y".equals(displayYn);
    }

    @Transient
    public boolean isOnSale() {
        return "Y".equals(saleYn);
    }
}
