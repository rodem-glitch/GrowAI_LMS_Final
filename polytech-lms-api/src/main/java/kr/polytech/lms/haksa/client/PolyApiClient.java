// polytech-lms-api/src/main/java/kr/polytech/lms/haksa/client/PolyApiClient.java
package kr.polytech.lms.haksa.client;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import kr.polytech.lms.haksa.config.PolySyncProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.net.URI;
import java.time.Duration;
import java.util.*;

/**
 * 학사포털(e-poly.kopo.ac.kr) API 클라이언트
 * poly_sync.jsp의 fetchPolyRaw() 함수를 Java로 구현
 *
 * 외부 학사시스템에서 View 데이터를 HTTP로 받아 로컬 DB에 미러링하는 스케줄러
 * 엔드포인트: https://e-poly.kopo.ac.kr/main/vpn_test.jsp
 */
@Slf4j
@Component
public class PolyApiClient {

    private final PolySyncProperties properties;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public PolyApiClient(PolySyncProperties properties, ObjectMapper objectMapper) {
        this.properties = properties;
        this.objectMapper = objectMapper;

        // 타임아웃 설정
        Duration timeout = properties.httpTimeout();
        var factory = new org.springframework.http.client.SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(timeout);
        factory.setReadTimeout(timeout);
        this.restTemplate = new RestTemplate(factory);
    }

    /**
     * fetchPolyRaw() 구현
     * 학사포털 View 데이터를 HTTP로 페이징 조회
     *
     * @param viewName   뷰 이름 (예: "COM.LMS_MEMBER_VIEW")
     * @param totalCount 전체 건수 (사전 조회 또는 추정)
     * @param maxRetries 최대 재시도 횟수
     * @param batchSize  한번에 가져올 건수
     * @param params     추가 파라미터
     * @return 조회된 전체 레코드 목록
     */
    public List<Map<String, Object>> fetchPolyRaw(
            String viewName,
            int totalCount,
            int maxRetries,
            int batchSize,
            String params) {

        List<Map<String, Object>> allRecords = new ArrayList<>();
        String endpoint = properties.endpoint();
        int pageCount = (totalCount + batchSize - 1) / batchSize; // 올림 나눗셈

        log.info("[PolyApiClient] fetchPolyRaw 시작: view={}, 예상건수={}, 배치={}, 페이지수={}",
                viewName, totalCount, batchSize, pageCount);

        for (int page = 0; page < pageCount; page++) {
            int offset = page * batchSize;
            boolean success = false;

            for (int retry = 0; retry < maxRetries; retry++) {
                try {
                    // 요청 URL 구성
                    String requestUrl = String.format(
                            "%s?view=%s&offset=%d&limit=%d%s",
                            endpoint, viewName, offset, batchSize,
                            (params != null && !params.isEmpty()) ? "&" + params : ""
                    );

                    HttpHeaders headers = new HttpHeaders();
                    headers.setAccept(List.of(MediaType.APPLICATION_JSON));
                    headers.set("User-Agent", "PolyLMS-Sync/1.0");
                    HttpEntity<Void> entity = new HttpEntity<>(headers);

                    ResponseEntity<String> response = restTemplate.exchange(
                            URI.create(requestUrl), HttpMethod.GET, entity, String.class);

                    if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                        Map<String, Object> body = objectMapper.readValue(
                                response.getBody(),
                                new TypeReference<>() {}
                        );

                        @SuppressWarnings("unchecked")
                        List<Map<String, Object>> records = (List<Map<String, Object>>) body.get("data");
                        if (records != null) {
                            allRecords.addAll(records);
                        }

                        log.debug("[PolyApiClient] page={}, 조회건수={}", page, records != null ? records.size() : 0);
                        success = true;
                        break; // 성공 시 재시도 루프 탈출
                    }

                } catch (Exception e) {
                    log.warn("[PolyApiClient] page={} 조회 실패 (retry={}/{}): {}",
                            page, retry + 1, maxRetries, e.getMessage());
                    if (retry < maxRetries - 1) {
                        try {
                            Thread.sleep(properties.retryDelayMs());
                        } catch (InterruptedException ie) {
                            Thread.currentThread().interrupt();
                            throw new RuntimeException("동기화 중단됨", ie);
                        }
                    }
                }
            }

            if (!success) {
                log.error("[PolyApiClient] page={} 최종 실패 ({}회 재시도 후)", page, maxRetries);
            }
        }

        log.info("[PolyApiClient] fetchPolyRaw 완료: view={}, 총 {}건 조회", viewName, allRecords.size());
        return allRecords;
    }

    /**
     * 회원 건수 사전 조회
     * VPN 연결 상태 확인 겸용
     */
    public int fetchMemberCount() {
        try {
            String requestUrl = properties.endpoint() + "?view=COM.LMS_MEMBER_VIEW&action=count";

            HttpHeaders headers = new HttpHeaders();
            headers.setAccept(List.of(MediaType.APPLICATION_JSON));
            HttpEntity<Void> entity = new HttpEntity<>(headers);

            ResponseEntity<String> response = restTemplate.exchange(
                    URI.create(requestUrl), HttpMethod.GET, entity, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                Map<String, Object> body = objectMapper.readValue(
                        response.getBody(), new TypeReference<>() {});
                Object count = body.get("count");
                if (count instanceof Number) {
                    return ((Number) count).intValue();
                }
            }
        } catch (Exception e) {
            log.warn("[PolyApiClient] 회원 건수 조회 실패: {}", e.getMessage());
        }
        return -1; // 실패 시 -1 반환
    }

    /**
     * VPN 연결 상태 확인
     */
    public boolean checkVpnConnection() {
        try {
            String requestUrl = properties.endpoint() + "?action=ping";
            ResponseEntity<String> response = restTemplate.getForEntity(
                    URI.create(requestUrl), String.class);
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            log.debug("[PolyApiClient] VPN 연결 확인 실패: {}", e.getMessage());
            return false;
        }
    }
}
