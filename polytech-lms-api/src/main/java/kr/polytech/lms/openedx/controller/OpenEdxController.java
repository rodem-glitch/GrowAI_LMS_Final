// polytech-lms-api/src/main/java/kr/polytech/lms/openedx/controller/OpenEdxController.java
package kr.polytech.lms.openedx.controller;

import kr.polytech.lms.openedx.client.OpenEdxClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Open edX 연동 API 컨트롤러
 * LMS 플랫폼 통합 엔드포인트
 */
@Slf4j
@RestController
@RequestMapping("/api/lms")
@RequiredArgsConstructor
public class OpenEdxController {

    private final OpenEdxClient openEdxClient;

    /**
     * Open edX 과정 목록 조회
     */
    @GetMapping("/courses")
    public ResponseEntity<Map<String, Object>> getCourses() {
        log.info("Open edX 과정 목록 조회");
        return ResponseEntity.ok(openEdxClient.getCourses());
    }

    /**
     * Open edX 과정 상세 조회
     */
    @GetMapping("/courses/{courseId}")
    public ResponseEntity<Map<String, Object>> getCourse(@PathVariable String courseId) {
        log.info("Open edX 과정 상세 조회: {}", courseId);
        return ResponseEntity.ok(openEdxClient.getCourse(courseId));
    }

    /**
     * 수강 등록
     */
    @PostMapping("/enroll")
    public ResponseEntity<Map<String, Object>> enrollUser(
            @RequestParam String courseId,
            @RequestParam String username) {
        log.info("수강 등록: courseId={}, username={}", courseId, username);
        return ResponseEntity.ok(openEdxClient.enrollUser(courseId, username));
    }

    /**
     * 사용자 수강 현황 조회
     */
    @GetMapping("/enrollments/{username}")
    public ResponseEntity<Map<String, Object>> getEnrollments(@PathVariable String username) {
        log.info("수강 현황 조회: {}", username);
        return ResponseEntity.ok(openEdxClient.getEnrollments(username));
    }

    /**
     * 진도 조회
     */
    @GetMapping("/progress/{courseId}/{username}")
    public ResponseEntity<Map<String, Object>> getProgress(
            @PathVariable String courseId,
            @PathVariable String username) {
        log.info("진도 조회: courseId={}, username={}", courseId, username);
        return ResponseEntity.ok(openEdxClient.getProgress(courseId, username));
    }
}
