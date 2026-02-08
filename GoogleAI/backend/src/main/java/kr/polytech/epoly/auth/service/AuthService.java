// auth/service/AuthService.java — 인증 서비스
package kr.polytech.epoly.auth.service;

import kr.polytech.epoly.auth.dto.LoginRequest;
import kr.polytech.epoly.auth.dto.LoginResponse;
import kr.polytech.epoly.config.JwtTokenProvider;
import kr.polytech.epoly.user.entity.User;
import kr.polytech.epoly.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final PasswordEncoder passwordEncoder;

    /** 로그인 */
    @Transactional
    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByUserId(request.getUserId())
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        if (!"ACTIVE".equals(user.getStatus())) {
            throw new IllegalArgumentException("비활성화된 계정입니다.");
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }

        // 마지막 로그인 시간 갱신
        user.setLastLoginAt(LocalDateTime.now());

        String accessToken = jwtTokenProvider.createAccessToken(user.getUserId(), user.getUserType());
        String refreshToken = jwtTokenProvider.createRefreshToken(user.getUserId(), user.getUserType());

        log.info("로그인 성공: userId={}, userType={}", user.getUserId(), user.getUserType());

        return LoginResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userId(user.getUserId())
                .name(user.getName())
                .userType(user.getUserType())
                .campus(user.getCampus())
                .department(user.getDepartment())
                .build();
    }

    /** 토큰 갱신 */
    public LoginResponse refreshToken(String refreshToken) {
        if (!jwtTokenProvider.validateToken(refreshToken)) {
            throw new IllegalArgumentException("유효하지 않은 리프레시 토큰입니다.");
        }

        String userId = jwtTokenProvider.getUserId(refreshToken);
        String role = jwtTokenProvider.getRole(refreshToken);

        User user = userRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        String newAccessToken = jwtTokenProvider.createAccessToken(userId, role);
        String newRefreshToken = jwtTokenProvider.createRefreshToken(userId, role);

        return LoginResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(newRefreshToken)
                .userId(user.getUserId())
                .name(user.getName())
                .userType(user.getUserType())
                .campus(user.getCampus())
                .department(user.getDepartment())
                .build();
    }
}
