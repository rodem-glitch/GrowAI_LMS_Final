// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/service/UserService.java
package kr.polytech.lms.legacy.service;

import kr.polytech.lms.legacy.dto.UserDto;
import kr.polytech.lms.legacy.entity.User;
import kr.polytech.lms.legacy.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * 사용자 Service
 * 레거시 UserDao의 비즈니스 로직을 Spring Service로 변환
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;

    /**
     * 로그인 ID로 사용자 조회
     */
    public Optional<UserDto> findByLoginId(String loginId, Long siteId) {
        return userRepository.findByLoginIdAndSiteId(loginId, siteId)
                .map(this::toDto);
    }

    /**
     * 사용자 상세 조회
     */
    public Optional<UserDto> findById(Long id) {
        return userRepository.findById(id)
                .filter(u -> u.getStatus() != -1)
                .map(this::toDto);
    }

    /**
     * 관리자 목록 조회
     */
    public List<UserDto> getManagers(Long siteId) {
        return getManagers(siteId, "C|A|S");
    }

    /**
     * 특정 유형 관리자 목록 조회
     */
    public List<UserDto> getManagers(Long siteId, String userKindFilter) {
        List<String> kinds = Arrays.asList(userKindFilter.split("\\|"));
        return userRepository.findManagers(siteId, kinds).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * 사용자 탈퇴 처리
     */
    @Transactional
    public boolean deleteUser(Long userId) {
        if (userId == null || userId == 0) {
            return false;
        }

        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty() || userOpt.get().getStatus() == -1) {
            return false;
        }

        int result = userRepository.deleteUser(userId);
        if (result > 0) {
            log.info("사용자 탈퇴 처리 완료 - userId: {}", userId);
            return true;
        }
        return false;
    }

    /**
     * 중복정보 확인
     */
    public boolean existsByDupinfo(String dupinfo, Long siteId) {
        return userRepository.existsByDupinfoAndSiteId(dupinfo, siteId);
    }

    /**
     * Entity to DTO 변환 (개인정보 마스킹 포함)
     */
    private UserDto toDto(User user) {
        return UserDto.builder()
                .id(user.getId())
                .siteId(user.getSiteId())
                .loginId(user.getLoginId())
                .userNm(user.getUserNm())
                .userNmMasked(maskName(user.getUserNm(), 1, 3))
                .userKind(user.getUserKind())
                .userKindLabel(user.getUserKindEnum().getLabel())
                .status(user.getStatus())
                .statusLabel(user.getUserStatusEnum().getLabel())
                .email(user.getEmail())
                .emailMasked(maskEmail(user.getEmail()))
                .mobile(user.getMobile())
                .mobileMasked(maskMobile(user.getMobile()))
                .gender(user.getGender())
                .deptId(user.getDeptId())
                .regDate(user.getRegDate())
                .connDate(user.getConnDate())
                .build();
    }

    /**
     * 이름 마스킹
     */
    private String maskName(String value, int pointer, int maxLen) {
        if (value == null || value.isEmpty()) {
            return "";
        }
        int len = Math.min(value.length(), maxLen);
        String target = value.substring(0, len);
        return target.replaceAll("(?<=.{" + pointer + "}).", "○");
    }

    /**
     * 휴대폰 마스킹
     */
    private String maskMobile(String value) {
        if (value == null || value.isEmpty()) {
            return "";
        }
        int len = Math.min(value.length(), 8);
        String target = value.substring(0, len);
        return target.replaceAll("(?<=.{4}).", "○");
    }

    /**
     * 이메일 마스킹
     */
    private String maskEmail(String value) {
        if (value == null || value.isEmpty() || !value.contains("@")) {
            return "";
        }
        String[] parts = value.split("@");
        String localPart = parts[0];
        String maskedLocal = localPart.replaceAll("(?<=.{1}).", "◯").substring(0, Math.min(localPart.length(), 5));
        return maskedLocal + "@◯";
    }
}
