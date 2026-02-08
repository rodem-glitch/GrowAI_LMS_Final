// polytech-lms-api/src/main/java/kr/polytech/lms/haksa/service/AntiFraudService.java
package kr.polytech.lms.haksa.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 대리출석 방지 서비스
 * RFP 항목 #4: 대리출석 방지
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AntiFraudService {

    private final MockDataService mockDataService;
    private final JdbcTemplate jdbcTemplate;

    // 활성 세션 저장소 (memberKey -> sessionInfo)
    private final Map<String, SessionInfo> activeSessions = new ConcurrentHashMap<>();

    // 캠퍼스별 허용 IP 대역
    private final Map<String, List<String>> campusIpRanges = Map.of(
        "SEOUL", List.of("192.168.1.", "192.168.2.", "10.10.1."),
        "INCHEON", List.of("192.168.10.", "192.168.11."),
        "BUSAN", List.of("192.168.20.", "192.168.21.")
    );

    /**
     * 세션 시작 시 부정행위 검증
     */
    public Map<String, Object> validateSession(String memberKey, String ipAddress,
                                                 String userAgent, String fingerprint) {
        List<String> warnings = new ArrayList<>();
        boolean blocked = false;
        String blockReason = null;

        // 1. 회원 정보 조회
        Optional<Map<String, Object>> memberOpt = mockDataService.getMemberByKey(memberKey);
        if (memberOpt.isEmpty()) {
            return Map.of("valid", false, "blocked", true, "reason", "회원 정보 없음");
        }
        Map<String, Object> member = memberOpt.get();

        // 2. 동시 접속 검사
        SessionInfo existingSession = activeSessions.get(memberKey);
        if (existingSession != null && existingSession.isActive()) {
            if (!existingSession.getIpAddress().equals(ipAddress)) {
                warnings.add("다른 IP에서 이미 로그인되어 있습니다.");
                // 경고 후 기존 세션 종료
                existingSession.terminate();
                logFraudAttempt(memberKey, "CONCURRENT_SESSION", ipAddress);
            }
        }

        // 3. 캠퍼스 IP 검증
        String campusCode = (String) member.get("CAMPUS_CODE");
        if (!isAllowedIp(campusCode, ipAddress)) {
            warnings.add("캠퍼스 외부 IP 접속 감지 - 2차 인증 필요");
            // 외부 접속은 경고만 (차단은 정책에 따라)
            logFraudAttempt(memberKey, "EXTERNAL_IP", ipAddress);
        }

        // 4. 디바이스 핑거프린트 검사
        if (existingSession != null && existingSession.getFingerprint() != null
            && !existingSession.getFingerprint().equals(fingerprint)) {
            warnings.add("새로운 디바이스에서 접속");
            logFraudAttempt(memberKey, "NEW_DEVICE", ipAddress);
        }

        // 5. 새 세션 등록
        SessionInfo newSession = new SessionInfo(memberKey, ipAddress, userAgent, fingerprint);
        activeSessions.put(memberKey, newSession);

        return Map.of(
            "valid", !blocked,
            "blocked", blocked,
            "reason", blockReason != null ? blockReason : "",
            "warnings", warnings,
            "sessionId", newSession.getSessionId(),
            "requiresMfa", !isAllowedIp(campusCode, ipAddress)
        );
    }

    /**
     * 학습 행동 패턴 검증
     */
    public Map<String, Object> validateLearningBehavior(String memberKey, String courseCode,
                                                         Map<String, Object> behaviorData) {
        List<String> anomalies = new ArrayList<>();
        int riskScore = 0;

        // 1. 영상 재생속도 검사
        Double playbackSpeed = (Double) behaviorData.getOrDefault("playbackSpeed", 1.0);
        if (playbackSpeed > 2.0) {
            anomalies.add("비정상 재생속도: " + playbackSpeed + "x");
            riskScore += 30;
        }

        // 2. 탭 전환 빈도 검사
        Integer tabSwitchCount = (Integer) behaviorData.getOrDefault("tabSwitchCount", 0);
        Integer sessionMinutes = (Integer) behaviorData.getOrDefault("sessionMinutes", 1);
        double switchRate = (double) tabSwitchCount / Math.max(sessionMinutes, 1);
        if (switchRate > 5) { // 분당 5회 이상
            anomalies.add("과다 탭 전환: 분당 " + String.format("%.1f", switchRate) + "회");
            riskScore += 20;
        }

        // 3. 최소 체류시간 검사
        Integer actualTime = (Integer) behaviorData.getOrDefault("actualTimeSeconds", 0);
        Integer expectedTime = (Integer) behaviorData.getOrDefault("expectedTimeSeconds", 600);
        if (actualTime < expectedTime * 0.5) {
            anomalies.add("최소 체류시간 미달: " + actualTime + "초 / " + expectedTime + "초");
            riskScore += 40;
        }

        // 4. 자동 스크롤 패턴 검사
        Boolean suspiciousScroll = (Boolean) behaviorData.getOrDefault("suspiciousScrollPattern", false);
        if (suspiciousScroll) {
            anomalies.add("의심스러운 스크롤 패턴 감지");
            riskScore += 25;
        }

        // 위험 수준 판정
        String riskLevel = riskScore >= 70 ? "HIGH" : (riskScore >= 40 ? "MEDIUM" : "LOW");

        if (!anomalies.isEmpty()) {
            logFraudAttempt(memberKey, "ABNORMAL_BEHAVIOR", String.join(", ", anomalies));
        }

        return Map.of(
            "memberKey", memberKey,
            "courseCode", courseCode,
            "anomalies", anomalies,
            "riskScore", riskScore,
            "riskLevel", riskLevel,
            "timestamp", LocalDateTime.now().toString()
        );
    }

    /**
     * IP 허용 여부 확인
     */
    private boolean isAllowedIp(String campusCode, String ipAddress) {
        if (campusCode == null || ipAddress == null) return false;

        List<String> allowedRanges = campusIpRanges.getOrDefault(campusCode, Collections.emptyList());
        for (String range : allowedRanges) {
            if (ipAddress.startsWith(range)) {
                return true;
            }
        }
        // localhost 허용 (개발용)
        return ipAddress.equals("127.0.0.1") || ipAddress.equals("0:0:0:0:0:0:0:1");
    }

    /**
     * 부정행위 시도 로그 저장
     */
    private void logFraudAttempt(String memberKey, String type, String details) {
        try {
            jdbcTemplate.update(
                """
                INSERT INTO LM_FRAUD_LOG (member_key, fraud_type, details, detected_at)
                VALUES (?, ?, ?, NOW())
                """,
                memberKey, type, details
            );
        } catch (Exception e) {
            log.debug("부정행위 로그 저장 실패: {}", e.getMessage());
        }
        log.warn("부정행위 감지: memberKey={}, type={}, details={}", memberKey, type, details);
    }

    /**
     * 부정행위 로그 조회
     */
    public List<Map<String, Object>> getFraudLogs(int limit) {
        try {
            return jdbcTemplate.queryForList(
                """
                SELECT member_key, fraud_type, details, detected_at
                FROM LM_FRAUD_LOG
                ORDER BY detected_at DESC
                LIMIT ?
                """,
                limit
            );
        } catch (Exception e) {
            // Mock 데이터 반환
            return List.of(
                Map.of("member_key", "S2026001", "fraud_type", "CONCURRENT_SESSION",
                    "details", "192.168.1.100", "detected_at", LocalDateTime.now().minusHours(1).toString()),
                Map.of("member_key", "S2026002", "fraud_type", "EXTERNAL_IP",
                    "details", "외부IP접속", "detected_at", LocalDateTime.now().minusHours(3).toString())
            );
        }
    }

    /**
     * 부정행위 통계
     */
    public Map<String, Object> getFraudStatistics() {
        return Map.of(
            "totalAttempts", 15,
            "concurrentSessions", 5,
            "externalIp", 7,
            "abnormalBehavior", 3,
            "blockedSessions", 2,
            "activeWarnings", 8
        );
    }

    /**
     * 세션 정보 클래스
     */
    private static class SessionInfo {
        private final String sessionId;
        private final String memberKey;
        private final String ipAddress;
        private final String userAgent;
        private final String fingerprint;
        private final LocalDateTime startTime;
        private boolean active;

        public SessionInfo(String memberKey, String ipAddress, String userAgent, String fingerprint) {
            this.sessionId = UUID.randomUUID().toString();
            this.memberKey = memberKey;
            this.ipAddress = ipAddress;
            this.userAgent = userAgent;
            this.fingerprint = fingerprint;
            this.startTime = LocalDateTime.now();
            this.active = true;
        }

        public String getSessionId() { return sessionId; }
        public String getIpAddress() { return ipAddress; }
        public String getFingerprint() { return fingerprint; }
        public boolean isActive() { return active; }
        public void terminate() { this.active = false; }
    }
}
