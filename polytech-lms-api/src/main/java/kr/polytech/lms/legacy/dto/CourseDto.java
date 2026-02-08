// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/dto/CourseDto.java
package kr.polytech.lms.legacy.dto;

import lombok.*;

/**
 * 과정 DTO
 * API 응답용 데이터 전송 객체
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CourseDto {
    private Long id;
    private Long siteId;
    private String courseNm;
    private String courseType;
    private String courseTypeLabel;
    private String onoffType;
    private String onoffTypeLabel;
    private Integer status;
    private String statusLabel;
    private String displayYn;
    private String saleYn;
    private Integer year;
    private Integer step;
    private String requestSdate;
    private String requestEdate;
    private String studySdate;
    private String studyEdate;
    private Integer lessonDay;
    private Long lessonCount;
    private Integer totalPlayTime;
    private String regDate;
}
