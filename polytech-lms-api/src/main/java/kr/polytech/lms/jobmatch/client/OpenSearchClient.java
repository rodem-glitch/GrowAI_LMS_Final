// polytech-lms-api/src/main/java/kr/polytech/lms/jobmatch/client/OpenSearchClient.java
package kr.polytech.lms.jobmatch.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.*;

/**
 * OpenSearch API 클라이언트
 * 채용 정보 검색 및 직무 매칭
 */
@Slf4j
@Component
public class OpenSearchClient {

    @Value("${opensearch.url:http://localhost:9200}")
    private String opensearchUrl;

    @Value("${opensearch.username:admin}")
    private String username;

    @Value("${opensearch.password:admin}")
    private String password;

    @Value("${opensearch.enabled:false}")
    private boolean enabled;

    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * 채용 공고 인덱싱
     */
    public boolean indexJob(String jobId, Map<String, Object> jobData) {
        if (!enabled) return false;

        try {
            String url = opensearchUrl + "/jobs/_doc/" + jobId;
            HttpEntity<Map<String, Object>> request = createRequest(jobData);

            restTemplate.exchange(url, HttpMethod.PUT, request, Map.class);
            log.debug("채용 공고 인덱싱 성공: jobId={}", jobId);
            return true;

        } catch (Exception e) {
            log.error("채용 공고 인덱싱 실패: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 채용 공고 검색
     */
    public List<Map<String, Object>> searchJobs(String keyword, String region,
                                                 String occupation, int size) {
        if (!enabled) {
            log.debug("OpenSearch 비활성화 상태");
            return Collections.emptyList();
        }

        try {
            Map<String, Object> query = buildSearchQuery(keyword, region, occupation, size);
            String url = opensearchUrl + "/jobs/_search";

            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, createRequest(query), Map.class);

            return extractHits(response.getBody());

        } catch (Exception e) {
            log.error("채용 공고 검색 실패: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    /**
     * 사용자 프로필 기반 채용 추천
     */
    public List<Map<String, Object>> getJobRecommendations(Map<String, Object> userProfile, int size) {
        if (!enabled) return Collections.emptyList();

        try {
            // 사용자 스킬, 전공, 희망 직종을 기반으로 검색
            List<String> skills = (List<String>) userProfile.getOrDefault("skills", Collections.emptyList());
            String major = (String) userProfile.getOrDefault("major", "");
            String preferredOccupation = (String) userProfile.getOrDefault("preferredOccupation", "");

            Map<String, Object> query = buildProfileMatchQuery(skills, major, preferredOccupation, size);
            String url = opensearchUrl + "/jobs/_search";

            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, createRequest(query), Map.class);

            return extractHits(response.getBody());

        } catch (Exception e) {
            log.error("채용 추천 조회 실패: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    /**
     * 유사 채용 공고 검색 (More Like This)
     */
    public List<Map<String, Object>> getSimilarJobs(String jobId, int size) {
        if (!enabled) return Collections.emptyList();

        try {
            Map<String, Object> query = Map.of(
                "query", Map.of(
                    "more_like_this", Map.of(
                        "fields", List.of("title", "description", "requirements", "skills"),
                        "like", List.of(Map.of("_index", "jobs", "_id", jobId)),
                        "min_term_freq", 1,
                        "min_doc_freq", 1
                    )
                ),
                "size", size
            );

            String url = opensearchUrl + "/jobs/_search";
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, createRequest(query), Map.class);

            return extractHits(response.getBody());

        } catch (Exception e) {
            log.error("유사 채용 공고 검색 실패: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    /**
     * 스킬 기반 자동완성
     */
    public List<String> suggestSkills(String prefix, int size) {
        if (!enabled) return Collections.emptyList();

        try {
            Map<String, Object> query = Map.of(
                "suggest", Map.of(
                    "skill-suggest", Map.of(
                        "prefix", prefix,
                        "completion", Map.of(
                            "field", "skills.suggest",
                            "size", size
                        )
                    )
                )
            );

            String url = opensearchUrl + "/jobs/_search";
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, createRequest(query), Map.class);

            // 자동완성 결과 추출
            Map<String, Object> body = response.getBody();
            if (body != null && body.containsKey("suggest")) {
                Map<String, Object> suggest = (Map<String, Object>) body.get("suggest");
                List<Map<String, Object>> suggestions = (List<Map<String, Object>>) suggest.get("skill-suggest");
                if (suggestions != null && !suggestions.isEmpty()) {
                    List<Map<String, Object>> options = (List<Map<String, Object>>) suggestions.get(0).get("options");
                    return options.stream()
                        .map(o -> (String) o.get("text"))
                        .toList();
                }
            }

        } catch (Exception e) {
            log.error("스킬 자동완성 실패: {}", e.getMessage());
        }

        return Collections.emptyList();
    }

    private Map<String, Object> buildSearchQuery(String keyword, String region,
                                                  String occupation, int size) {
        List<Map<String, Object>> must = new ArrayList<>();

        if (keyword != null && !keyword.isEmpty()) {
            must.add(Map.of("multi_match", Map.of(
                "query", keyword,
                "fields", List.of("title^2", "company", "description", "requirements")
            )));
        }

        if (region != null && !region.isEmpty()) {
            must.add(Map.of("term", Map.of("region", region)));
        }

        if (occupation != null && !occupation.isEmpty()) {
            must.add(Map.of("term", Map.of("occupation", occupation)));
        }

        if (must.isEmpty()) {
            must.add(Map.of("match_all", Map.of()));
        }

        return Map.of(
            "query", Map.of("bool", Map.of("must", must)),
            "size", size,
            "sort", List.of(Map.of("postedDate", Map.of("order", "desc")))
        );
    }

    private Map<String, Object> buildProfileMatchQuery(List<String> skills, String major,
                                                        String preferredOccupation, int size) {
        List<Map<String, Object>> should = new ArrayList<>();

        // 스킬 매칭
        if (!skills.isEmpty()) {
            should.add(Map.of("terms", Map.of("skills", skills, "boost", 3)));
        }

        // 전공 매칭
        if (major != null && !major.isEmpty()) {
            should.add(Map.of("match", Map.of("requirements", Map.of("query", major, "boost", 2))));
        }

        // 희망 직종 매칭
        if (preferredOccupation != null && !preferredOccupation.isEmpty()) {
            should.add(Map.of("match", Map.of("occupation", Map.of("query", preferredOccupation, "boost", 2))));
        }

        if (should.isEmpty()) {
            return Map.of("query", Map.of("match_all", Map.of()), "size", size);
        }

        return Map.of(
            "query", Map.of("bool", Map.of("should", should, "minimum_should_match", 1)),
            "size", size
        );
    }

    private HttpEntity<Map<String, Object>> createRequest(Map<String, Object> body) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBasicAuth(username, password);
        return new HttpEntity<>(body, headers);
    }

    private List<Map<String, Object>> extractHits(Map<String, Object> response) {
        if (response == null) return Collections.emptyList();

        try {
            Map<String, Object> hits = (Map<String, Object>) response.get("hits");
            if (hits != null) {
                List<Map<String, Object>> hitList = (List<Map<String, Object>>) hits.get("hits");
                if (hitList != null) {
                    return hitList.stream()
                        .map(hit -> {
                            Map<String, Object> source = (Map<String, Object>) hit.get("_source");
                            source.put("_id", hit.get("_id"));
                            source.put("_score", hit.get("_score"));
                            return source;
                        })
                        .toList();
                }
            }
        } catch (Exception e) {
            log.error("검색 결과 파싱 실패: {}", e.getMessage());
        }

        return Collections.emptyList();
    }
}
