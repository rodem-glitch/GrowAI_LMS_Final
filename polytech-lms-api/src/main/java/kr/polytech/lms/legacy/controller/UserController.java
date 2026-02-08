// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/controller/UserController.java
package kr.polytech.lms.legacy.controller;

import kr.polytech.lms.legacy.dto.UserDto;
import kr.polytech.lms.legacy.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 사용자 REST API Controller
 * 레거시 JSP 컨트롤러를 REST API로 변환
 */
@Slf4j
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /**
     * 사용자 상세 조회
     */
    @GetMapping("/{id}")
    public ResponseEntity<UserDto> getUser(@PathVariable Long id) {
        log.debug("사용자 조회 - id: {}", id);
        return userService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * 로그인 ID로 사용자 조회
     */
    @GetMapping("/login/{loginId}")
    public ResponseEntity<UserDto> getUserByLoginId(
            @PathVariable String loginId,
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId) {
        log.debug("사용자 조회 (로그인ID) - loginId: {}, siteId: {}", loginId, siteId);
        return userService.findByLoginId(loginId, siteId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * 관리자 목록 조회
     */
    @GetMapping("/managers")
    public ResponseEntity<List<UserDto>> getManagers(
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId,
            @RequestParam(required = false, defaultValue = "C|A|S") String kinds) {
        log.debug("관리자 목록 조회 - siteId: {}, kinds: {}", siteId, kinds);
        List<UserDto> managers = userService.getManagers(siteId, kinds);
        return ResponseEntity.ok(managers);
    }

    /**
     * 사용자 탈퇴 처리
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        log.info("사용자 탈퇴 요청 - id: {}", id);
        boolean result = userService.deleteUser(id);
        if (result) {
            return ResponseEntity.ok().build();
        }
        return ResponseEntity.notFound().build();
    }
}
