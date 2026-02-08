// polytech-lms-api/src/main/java/kr/polytech/lms/bbb/client/BigBlueButtonClient.java
package kr.polytech.lms.bbb.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Map;
import java.util.TreeMap;

/**
 * BigBlueButton API 클라이언트
 * 화상강의 생성, 참여, 녹화 관리
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class BigBlueButtonClient {

    private final BigBlueButtonProperties properties;
    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * 회의실 생성
     */
    public Map<String, Object> createMeeting(String meetingId, String meetingName,
                                              String attendeePw, String moderatorPw) {
        Map<String, String> params = new TreeMap<>();
        params.put("meetingID", meetingId);
        params.put("name", meetingName);
        params.put("attendeePW", attendeePw);
        params.put("moderatorPW", moderatorPw);
        params.put("welcome", "한국폴리텍대학 화상강의에 오신 것을 환영합니다.");
        params.put("record", "true");
        params.put("autoStartRecording", "false");
        params.put("allowStartStopRecording", "true");

        return callApi("create", params);
    }

    /**
     * 회의실 참여 URL 생성
     */
    public String getJoinUrl(String meetingId, String userName, String password, boolean isModerator) {
        Map<String, String> params = new TreeMap<>();
        params.put("meetingID", meetingId);
        params.put("fullName", userName);
        params.put("password", password);
        params.put("redirect", "true");

        String queryString = buildQueryString(params);
        String checksum = generateChecksum("join", queryString);

        return properties.baseUrl() + "/api/join?" + queryString + "&checksum=" + checksum;
    }

    /**
     * 회의실 정보 조회
     */
    public Map<String, Object> getMeetingInfo(String meetingId) {
        Map<String, String> params = new TreeMap<>();
        params.put("meetingID", meetingId);
        return callApi("getMeetingInfo", params);
    }

    /**
     * 회의실 종료
     */
    public Map<String, Object> endMeeting(String meetingId, String moderatorPw) {
        Map<String, String> params = new TreeMap<>();
        params.put("meetingID", meetingId);
        params.put("password", moderatorPw);
        return callApi("end", params);
    }

    /**
     * 활성 회의실 목록 조회
     */
    public Map<String, Object> getMeetings() {
        return callApi("getMeetings", new TreeMap<>());
    }

    /**
     * 녹화 목록 조회
     */
    public Map<String, Object> getRecordings(String meetingId) {
        Map<String, String> params = new TreeMap<>();
        params.put("meetingID", meetingId);
        return callApi("getRecordings", params);
    }

    /**
     * 회의실 실행 여부 확인
     */
    public boolean isMeetingRunning(String meetingId) {
        Map<String, String> params = new TreeMap<>();
        params.put("meetingID", meetingId);
        Map<String, Object> result = callApi("isMeetingRunning", params);
        return "true".equals(String.valueOf(result.get("running")));
    }

    private Map<String, Object> callApi(String action, Map<String, String> params) {
        if (!properties.enabled()) {
            log.debug("BigBlueButton 비활성화 상태");
            return Map.of("returncode", "FAILED", "message", "BBB disabled");
        }

        String queryString = buildQueryString(params);
        String checksum = generateChecksum(action, queryString);
        String url = properties.baseUrl() + "/api/" + action + "?" + queryString + "&checksum=" + checksum;

        try {
            String response = restTemplate.getForObject(url, String.class);
            log.debug("BBB API 응답: {}", response);
            return parseXmlResponse(response);
        } catch (Exception e) {
            log.error("BBB API 호출 실패: {}", e.getMessage());
            return Map.of("returncode", "FAILED", "message", e.getMessage());
        }
    }

    private String buildQueryString(Map<String, String> params) {
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, String> entry : params.entrySet()) {
            if (sb.length() > 0) sb.append("&");
            sb.append(URLEncoder.encode(entry.getKey(), StandardCharsets.UTF_8));
            sb.append("=");
            sb.append(URLEncoder.encode(entry.getValue(), StandardCharsets.UTF_8));
        }
        return sb.toString();
    }

    private String generateChecksum(String action, String queryString) {
        try {
            String data = action + queryString + properties.secret();
            MessageDigest md = MessageDigest.getInstance("SHA-1");
            byte[] digest = md.digest(data.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            log.error("체크섬 생성 실패: {}", e.getMessage());
            return "";
        }
    }

    private Map<String, Object> parseXmlResponse(String xml) {
        // 간단한 XML 파싱 (실제로는 JAXB나 Jackson XML 사용 권장)
        Map<String, Object> result = new TreeMap<>();

        if (xml.contains("<returncode>SUCCESS</returncode>")) {
            result.put("returncode", "SUCCESS");
        } else {
            result.put("returncode", "FAILED");
        }

        // meetingID 추출
        if (xml.contains("<meetingID>")) {
            int start = xml.indexOf("<meetingID>") + 11;
            int end = xml.indexOf("</meetingID>");
            if (end > start) {
                result.put("meetingID", xml.substring(start, end));
            }
        }

        // running 추출
        if (xml.contains("<running>")) {
            int start = xml.indexOf("<running>") + 9;
            int end = xml.indexOf("</running>");
            if (end > start) {
                result.put("running", xml.substring(start, end));
            }
        }

        return result;
    }
}
