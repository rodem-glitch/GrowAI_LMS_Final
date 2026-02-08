// auth/dto/LoginResponse.java — 로그인 응답 DTO
package kr.polytech.epoly.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class LoginResponse {
    private String accessToken;
    private String refreshToken;
    private String userId;
    private String name;
    private String userType;
    private String campus;
    private String department;
}
