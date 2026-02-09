// polytech-lms-api/src/main/java/kr/polytech/lms/exam/controller/ExamSecurityController.java
package kr.polytech.lms.exam.controller;

import kr.polytech.lms.exam.service.SafeExamBrowserService;
import kr.polytech.lms.security.error.ExternalServiceException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * 시험 보안 API 컨트롤러
 * Safe Exam Browser 연동 및 부정행위 방지
 */
@Slf4j
@RestController
@RequestMapping("/api/exam-security")
@RequiredArgsConstructor
public class ExamSecurityController {

    private final SafeExamBrowserService sebService;

    /**
     * SEB 설정 파일 다운로드
     */
    @GetMapping("/seb-config/{examId}")
    public ResponseEntity<?> getSebConfig(
            @PathVariable Long examId,
            @RequestParam String examUrl,
            @RequestParam(required = false) Boolean allowQuit,
            @RequestParam(required = false) Boolean enableRightMouse) {

        log.info("SEB 설정 파일 요청: examId={}, examUrl={}", examId, examUrl);

        try {
            Map<String, Object> options = Map.of(
                "allowQuit", allowQuit != null && allowQuit,
                "enableRightMouse", enableRightMouse != null && enableRightMouse
            );

            String config = sebService.generateSebConfig(examId, examUrl, options);
            String configHash = sebService.generateConfigKeyHash(config);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_XML);
            headers.set("Content-Disposition", "attachment; filename=exam-" + examId + ".seb");
            headers.set("X-SEB-Config-Hash", configHash);

            return ResponseEntity.ok().headers(headers).body(config);
        } catch (Exception e) {
            log.error("SEB 설정 파일 생성 실패: examId={}", examId, e);
            throw new ExternalServiceException("SEB", "EXAM_001",
                "SEB 설정 파일 생성에 실패했습니다.", e);
        }
    }

    /**
     * SEB 시작 링크 생성
     */
    @GetMapping("/seb-link/{examId}")
    public ResponseEntity<Map<String, Object>> getSebLink(
            @PathVariable Long examId,
            @RequestParam String baseUrl) {

        log.info("SEB 링크 생성: examId={}", examId);

        try {
            String configUrl = baseUrl + "/api/exam-security/seb-config/" + examId + "?examUrl=" + baseUrl + "/exam/" + examId;
            String sebLink = sebService.generateSebLink(configUrl);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("examId", examId, "sebLink", sebLink, "configUrl", configUrl),
                "timestamp", LocalDateTime.now().toString()
            ));
        } catch (Exception e) {
            log.error("SEB 링크 생성 실패: examId={}", examId, e);
            throw new ExternalServiceException("SEB", "EXAM_001",
                "SEB 링크 생성에 실패했습니다.", e);
        }
    }

    /**
     * SEB 접근 검증
     */
    @PostMapping("/validate")
    public ResponseEntity<Map<String, Object>> validateAccess(
            @RequestHeader(value = "User-Agent", required = false) String userAgent,
            @RequestHeader(value = "X-SafeExamBrowser-RequestHash", required = false) String browserExamKey,
            @RequestBody Map<String, Object> request) {

        Object examIdObj = request.get("examId");
        if (examIdObj == null) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "시험 ID(examId)가 필요합니다.",
                "timestamp", LocalDateTime.now().toString()));
        }

        Long examId = Long.valueOf(examIdObj.toString());
        String examUrl = (String) request.get("examUrl");

        log.info("SEB 접근 검증 요청: examId={}", examId);

        try {
            boolean isAllowed = sebService.isAccessAllowed(userAgent, browserExamKey, examId);

            if (isAllowed && browserExamKey != null) {
                String configKeyHash = (String) request.get("configKeyHash");
                if (configKeyHash != null) {
                    isAllowed = sebService.validateSebRequest(examUrl, browserExamKey, configKeyHash);
                }
            }

            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of(
                    "examId", examId,
                    "allowed", isAllowed,
                    "sebDetected", userAgent != null && userAgent.contains("SEB"),
                    "message", isAllowed ? "접근 허용" : "Safe Exam Browser로만 접근 가능합니다."
                ),
                "timestamp", LocalDateTime.now().toString()
            ));
        } catch (Exception e) {
            log.error("SEB 접근 검증 실패: examId={}", examId, e);
            throw new ExternalServiceException("SEB", "EXAM_001",
                "시험 접근 검증에 실패했습니다.", e);
        }
    }

    /**
     * 시험 중 부정행위 이벤트 기록
     */
    @PostMapping("/violation")
    public ResponseEntity<Map<String, Object>> reportViolation(
            @RequestBody Map<String, Object> violation) {

        Object examIdObj = violation.get("examId");
        Object userIdObj = violation.get("userId");
        if (examIdObj == null || userIdObj == null) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "시험 ID(examId)와 사용자 ID(userId)가 필요합니다.",
                "timestamp", LocalDateTime.now().toString()));
        }

        Long examId = Long.valueOf(examIdObj.toString());
        Long userId = Long.valueOf(userIdObj.toString());
        String violationType = (String) violation.get("type");
        String description = (String) violation.get("description");

        log.warn("부정행위 감지: examId={}, userId={}, type={}, desc={}",
                examId, userId, violationType, description);

        // TODO: DB에 부정행위 기록 저장

        return ResponseEntity.ok(Map.of(
            "success", true,
            "data", Map.of(
                "recorded", true,
                "examId", examId,
                "userId", userId,
                "violationType", violationType != null ? violationType : "UNKNOWN"
            ),
            "timestamp", LocalDateTime.now().toString()
        ));
    }
}
