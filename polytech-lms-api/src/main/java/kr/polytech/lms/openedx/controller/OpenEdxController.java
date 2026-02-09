// polytech-lms-api/src/main/java/kr/polytech/lms/openedx/controller/OpenEdxController.java
package kr.polytech.lms.openedx.controller;

import kr.polytech.lms.openedx.client.OpenEdxClient;
import kr.polytech.lms.security.error.ExternalServiceException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
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
        try {
            Map<String, Object> courses = openEdxClient.getCourses();
            return ResponseEntity.ok(Map.of("success", true, "data", courses,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Open edX 과정 목록 조회 실패", e);
            throw new ExternalServiceException("OpenEdx", "COURSE_001",
                "강좌 목록 조회에 실패했습니다.", e);
        }
    }

    /**
     * Open edX 과정 상세 조회
     */
    @GetMapping("/courses/{courseId}")
    public ResponseEntity<Map<String, Object>> getCourse(@PathVariable String courseId) {
        log.info("Open edX 과정 상세 조회: {}", courseId);
        try {
            Map<String, Object> course = openEdxClient.getCourse(courseId);
            return ResponseEntity.ok(Map.of("success", true, "data", course,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Open edX 과정 상세 조회 실패: courseId={}", courseId, e);
            throw new ExternalServiceException("OpenEdx", "COURSE_001",
                "강좌를 찾을 수 없습니다.", e);
        }
    }

    /**
     * 수강 등록
     */
    @PostMapping("/enroll")
    public ResponseEntity<Map<String, Object>> enrollUser(
            @RequestParam String courseId,
            @RequestParam String username) {
        log.info("수강 등록: courseId={}, username={}", courseId, username);
        try {
            Map<String, Object> result = openEdxClient.enrollUser(courseId, username);
            return ResponseEntity.ok(Map.of("success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("수강 등록 실패: courseId={}, username={}", courseId, username, e);
            throw new ExternalServiceException("OpenEdx", "COURSE_002",
                "수강 등록에 실패했습니다.", e);
        }
    }

    /**
     * 사용자 수강 현황 조회
     */
    @GetMapping("/enrollments/{username}")
    public ResponseEntity<Map<String, Object>> getEnrollments(@PathVariable String username) {
        log.info("수강 현황 조회: {}", username);
        try {
            Map<String, Object> enrollments = openEdxClient.getEnrollments(username);
            return ResponseEntity.ok(Map.of("success", true, "data", enrollments,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("수강 현황 조회 실패: username={}", username, e);
            throw new ExternalServiceException("OpenEdx", "COURSE_001",
                "수강 현황 조회에 실패했습니다.", e);
        }
    }

    /**
     * 진도 조회
     */
    @GetMapping("/progress/{courseId}/{username}")
    public ResponseEntity<Map<String, Object>> getProgress(
            @PathVariable String courseId,
            @PathVariable String username) {
        log.info("진도 조회: courseId={}, username={}", courseId, username);
        try {
            Map<String, Object> progress = openEdxClient.getProgress(courseId, username);
            return ResponseEntity.ok(Map.of("success", true, "data", progress,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("진도 조회 실패: courseId={}, username={}", courseId, username, e);
            throw new ExternalServiceException("OpenEdx", "COURSE_001",
                "진도 조회에 실패했습니다.", e);
        }
    }
}
