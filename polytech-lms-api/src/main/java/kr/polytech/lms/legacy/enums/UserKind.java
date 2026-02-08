// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/enums/UserKind.java
package kr.polytech.lms.legacy.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * 사용자 유형 Enum
 * 레거시 UserDao의 kinds 배열을 Enum으로 변환
 */
@Getter
@RequiredArgsConstructor
public enum UserKind {
    USER("U", "회원"),
    COURSE_MANAGER("C", "과정운영자"),
    DEPT_MANAGER("D", "소속운영자"),
    ADMIN("A", "운영자"),
    SUPER_ADMIN("S", "최고관리자");

    private final String code;
    private final String label;

    public static UserKind fromCode(String code) {
        for (UserKind kind : values()) {
            if (kind.code.equals(code)) {
                return kind;
            }
        }
        return USER;
    }

    public boolean isAdmin() {
        return this == COURSE_MANAGER || this == DEPT_MANAGER || this == ADMIN || this == SUPER_ADMIN;
    }
}
