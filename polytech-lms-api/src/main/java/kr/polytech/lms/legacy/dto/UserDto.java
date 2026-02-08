// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/dto/UserDto.java
package kr.polytech.lms.legacy.dto;

import lombok.*;

/**
 * 사용자 DTO
 * API 응답용 데이터 전송 객체 (개인정보 마스킹 처리)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDto {
    private Long id;
    private Long siteId;
    private String loginId;
    private String userNm;
    private String userNmMasked;
    private String userKind;
    private String userKindLabel;
    private Integer status;
    private String statusLabel;
    private String email;
    private String emailMasked;
    private String mobile;
    private String mobileMasked;
    private String gender;
    private Long deptId;
    private String regDate;
    private String connDate;
}
