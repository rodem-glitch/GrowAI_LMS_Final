// polytech-lms-api/src/main/java/kr/polytech/lms/exam/service/SafeExamBrowserService.java
package kr.polytech.lms.exam.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.Map;

/**
 * Safe Exam Browser 연동 서비스
 * 시험 환경 보안 및 부정행위 방지
 */
@Slf4j
@Service
public class SafeExamBrowserService {

    private static final String SEB_CONFIG_KEY = "polytech-lms-seb-key";

    /**
     * SEB 설정 파일 생성 (seb:// 프로토콜용)
     */
    public String generateSebConfig(Long examId, String examUrl, Map<String, Object> options) {
        StringBuilder config = new StringBuilder();
        config.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        config.append("<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n");
        config.append("<plist version=\"1.0\">\n");
        config.append("<dict>\n");

        // 시작 URL
        config.append("  <key>startURL</key>\n");
        config.append("  <string>").append(examUrl).append("</string>\n");

        // 기본 보안 설정
        config.append("  <key>allowQuit</key>\n");
        config.append("  <").append(getBoolean(options, "allowQuit", false)).append("/>\n");

        config.append("  <key>quitURLConfirm</key>\n");
        config.append("  <true/>\n");

        config.append("  <key>allowSwitchToApplications</key>\n");
        config.append("  <false/>\n");

        config.append("  <key>allowFlashFullscreen</key>\n");
        config.append("  <false/>\n");

        // 브라우저 설정
        config.append("  <key>browserViewMode</key>\n");
        config.append("  <integer>1</integer>\n");

        config.append("  <key>mainBrowserWindowWidth</key>\n");
        config.append("  <string>100%</string>\n");

        config.append("  <key>mainBrowserWindowHeight</key>\n");
        config.append("  <string>100%</string>\n");

        // 키보드/마우스 설정
        config.append("  <key>enableAltEsc</key>\n");
        config.append("  <false/>\n");

        config.append("  <key>enableAltTab</key>\n");
        config.append("  <false/>\n");

        config.append("  <key>enableCtrlEsc</key>\n");
        config.append("  <false/>\n");

        config.append("  <key>enablePrintScreen</key>\n");
        config.append("  <false/>\n");

        config.append("  <key>enableRightMouse</key>\n");
        config.append("  <").append(getBoolean(options, "enableRightMouse", false)).append("/>\n");

        // 시험 ID 메타데이터
        config.append("  <key>examId</key>\n");
        config.append("  <string>").append(examId).append("</string>\n");

        config.append("</dict>\n");
        config.append("</plist>");

        return config.toString();
    }

    /**
     * SEB 요청 검증 (Browser Exam Key 확인)
     */
    public boolean validateSebRequest(String requestUrl, String browserExamKey, String configKeyHash) {
        try {
            // Browser Exam Key 검증
            String expectedKey = generateBrowserExamKey(requestUrl, configKeyHash);
            boolean isValid = expectedKey.equalsIgnoreCase(browserExamKey);

            log.info("SEB 요청 검증: url={}, valid={}", requestUrl, isValid);
            return isValid;
        } catch (Exception e) {
            log.error("SEB 검증 실패: {}", e.getMessage());
            return false;
        }
    }

    /**
     * Browser Exam Key 생성
     */
    public String generateBrowserExamKey(String url, String configKeyHash) {
        try {
            String data = url + configKeyHash;
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(data.getBytes(StandardCharsets.UTF_8));
            return bytesToHex(hash);
        } catch (Exception e) {
            log.error("Browser Exam Key 생성 실패: {}", e.getMessage());
            return "";
        }
    }

    /**
     * Config Key Hash 생성
     */
    public String generateConfigKeyHash(String sebConfig) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(sebConfig.getBytes(StandardCharsets.UTF_8));
            return bytesToHex(hash);
        } catch (Exception e) {
            log.error("Config Key Hash 생성 실패: {}", e.getMessage());
            return "";
        }
    }

    /**
     * SEB 시작 링크 생성 (seb:// 프로토콜)
     */
    public String generateSebLink(String configUrl) {
        // HTTPS URL을 SEB 프로토콜로 변환
        String sebUrl = configUrl.replace("https://", "sebs://").replace("http://", "seb://");
        return sebUrl;
    }

    /**
     * 시험 접근 허용 여부 확인
     */
    public boolean isAccessAllowed(String userAgent, String browserExamKey, Long examId) {
        // SEB User-Agent 확인
        boolean isSebBrowser = userAgent != null && userAgent.contains("SEB");

        if (!isSebBrowser) {
            log.warn("SEB 브라우저가 아닌 접근 시도: examId={}", examId);
            return false;
        }

        // Browser Exam Key 존재 확인
        if (browserExamKey == null || browserExamKey.isEmpty()) {
            log.warn("Browser Exam Key 누락: examId={}", examId);
            return false;
        }

        return true;
    }

    private String getBoolean(Map<String, Object> options, String key, boolean defaultValue) {
        if (options != null && options.containsKey(key)) {
            return Boolean.TRUE.equals(options.get(key)) ? "true" : "false";
        }
        return defaultValue ? "true" : "false";
    }

    private String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }
}
