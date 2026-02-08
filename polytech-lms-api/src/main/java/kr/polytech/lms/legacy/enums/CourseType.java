// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/enums/CourseType.java
package kr.polytech.lms.legacy.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * 과정 유형 Enum
 * 레거시 DAO의 types 배열을 Enum으로 변환
 */
@Getter
@RequiredArgsConstructor
public enum CourseType {
    REGULAR("R", "정규"),
    ALWAYS("A", "상시");

    private final String code;
    private final String label;

    public static CourseType fromCode(String code) {
        for (CourseType type : values()) {
            if (type.code.equals(code)) {
                return type;
            }
        }
        return REGULAR;
    }
}
