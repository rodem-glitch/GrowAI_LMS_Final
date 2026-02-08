// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/enums/CourseStatus.java
package kr.polytech.lms.legacy.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * 과정 상태 Enum
 * 레거시 DAO의 statusList 배열을 Enum으로 변환
 */
@Getter
@RequiredArgsConstructor
public enum CourseStatus {
    ACTIVE("1", "정상"),
    INACTIVE("0", "중지"),
    DELETED("-1", "삭제");

    private final String code;
    private final String label;

    public static CourseStatus fromCode(String code) {
        for (CourseStatus status : values()) {
            if (status.code.equals(code)) {
                return status;
            }
        }
        return INACTIVE;
    }
}
