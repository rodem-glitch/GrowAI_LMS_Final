// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/enums/UserStatus.java
package kr.polytech.lms.legacy.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * 사용자 상태 Enum
 * 레거시 UserDao의 statusList 배열을 Enum으로 변환
 */
@Getter
@RequiredArgsConstructor
public enum UserStatus {
    ACTIVE("1", "정상"),
    INACTIVE("0", "중지"),
    DORMANT("30", "휴면대상"),
    WITHDRAWN("-2", "탈퇴"),
    DELETED("-1", "삭제");

    private final String code;
    private final String label;

    public static UserStatus fromCode(String code) {
        for (UserStatus status : values()) {
            if (status.code.equals(code)) {
                return status;
            }
        }
        return INACTIVE;
    }
}
