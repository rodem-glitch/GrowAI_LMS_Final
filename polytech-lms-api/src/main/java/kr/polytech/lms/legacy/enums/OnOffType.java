// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/enums/OnOffType.java
package kr.polytech.lms.legacy.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * 온/오프라인 유형 Enum
 * 레거시 DAO의 onoffTypes 배열을 Enum으로 변환
 */
@Getter
@RequiredArgsConstructor
public enum OnOffType {
    ONLINE("N", "온라인"),
    OFFLINE("F", "집합"),
    BLENDED("B", "혼합"),
    PACKAGE("P", "패키지");

    private final String code;
    private final String label;

    public static OnOffType fromCode(String code) {
        for (OnOffType type : values()) {
            if (type.code.equals(code)) {
                return type;
            }
        }
        return ONLINE;
    }
}
