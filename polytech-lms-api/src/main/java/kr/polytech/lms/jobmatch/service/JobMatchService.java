// polytech-lms-api/src/main/java/kr/polytech/lms/jobmatch/service/JobMatchService.java
package kr.polytech.lms.jobmatch.service;

import kr.polytech.lms.jobmatch.client.OpenSearchClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * 채용 매칭 서비스
 * OpenSearch 기반 직무 매칭 및 추천
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class JobMatchService {

    private final OpenSearchClient openSearchClient;
    private final JdbcTemplate jdbcTemplate;

    /**
     * 채용 공고 검색
     */
    public Map<String, Object> searchJobs(String keyword, String region,
                                          String occupation, int page, int size) {
        int offset = page * size;

        List<Map<String, Object>> jobs = openSearchClient.searchJobs(
            keyword, region, occupation, size + offset);

        // 페이지네이션 적용
        List<Map<String, Object>> pagedJobs = jobs.stream()
            .skip(offset)
            .limit(size)
            .toList();

        return Map.of(
            "jobs", pagedJobs,
            "total", jobs.size(),
            "page", page,
            "size", size
        );
    }

    /**
     * 사용자 프로필 기반 채용 추천
     */
    public Map<String, Object> getPersonalizedJobRecommendations(Long userId, int limit) {
        // 사용자 프로필 조회
        Map<String, Object> userProfile = getUserProfile(userId);

        // OpenSearch에서 매칭 검색
        List<Map<String, Object>> recommendations = openSearchClient.getJobRecommendations(
            userProfile, limit);

        // 매칭 점수 계산
        recommendations = calculateMatchScores(recommendations, userProfile);

        return Map.of(
            "userId", userId,
            "profile", userProfile,
            "recommendations", recommendations,
            "count", recommendations.size()
        );
    }

    /**
     * 학과별 채용 추천
     */
    public List<Map<String, Object>> getJobsByDepartment(String departmentCode, int limit) {
        // 학과 코드로 관련 직종 매핑
        List<String> relatedOccupations = getRelatedOccupations(departmentCode);

        if (relatedOccupations.isEmpty()) {
            return Collections.emptyList();
        }

        // 관련 직종의 채용 공고 검색
        List<Map<String, Object>> allJobs = new ArrayList<>();
        for (String occupation : relatedOccupations) {
            List<Map<String, Object>> jobs = openSearchClient.searchJobs(
                null, null, occupation, limit / relatedOccupations.size() + 1);
            allJobs.addAll(jobs);
        }

        return allJobs.stream()
            .limit(limit)
            .toList();
    }

    /**
     * 유사 채용 공고 조회
     */
    public List<Map<String, Object>> getSimilarJobs(String jobId, int limit) {
        return openSearchClient.getSimilarJobs(jobId, limit);
    }

    /**
     * 스킬 자동완성
     */
    public List<String> suggestSkills(String prefix) {
        return openSearchClient.suggestSkills(prefix, 10);
    }

    /**
     * 사용자 프로필 조회
     */
    private Map<String, Object> getUserProfile(Long userId) {
        Map<String, Object> profile = new HashMap<>();

        try {
            // 사용자 기본 정보
            Map<String, Object> userInfo = jdbcTemplate.queryForMap(
                "SELECT user_nm, dept_id FROM TB_USER WHERE id = ?", userId);
            profile.putAll(userInfo);

            // 수료한 과정에서 스킬 추출
            List<String> skills = jdbcTemplate.queryForList(
                """
                SELECT DISTINCT c.course_nm
                FROM LM_COURSE_USER cu
                JOIN LM_COURSE c ON cu.course_id = c.id
                WHERE cu.user_id = ? AND cu.complete_yn = 'Y'
                LIMIT 20
                """,
                String.class, userId);
            profile.put("skills", skills);

            // 학과 정보로 전공 추정
            Long deptId = (Long) userInfo.get("dept_id");
            if (deptId != null) {
                try {
                    String deptName = jdbcTemplate.queryForObject(
                        "SELECT dept_nm FROM TB_DEPT WHERE id = ?",
                        String.class, deptId);
                    profile.put("major", deptName);
                } catch (Exception ignored) {}
            }

        } catch (Exception e) {
            log.error("사용자 프로필 조회 실패: {}", e.getMessage());
        }

        return profile;
    }

    /**
     * 학과별 관련 직종 매핑
     */
    private List<String> getRelatedOccupations(String departmentCode) {
        // 학과-직종 매핑 테이블 조회 (간소화된 버전)
        Map<String, List<String>> mappings = Map.of(
            "SW", List.of("소프트웨어개발", "웹개발", "앱개발", "AI개발"),
            "IT", List.of("IT", "정보보안", "네트워크", "시스템관리"),
            "ME", List.of("기계", "자동차", "로봇", "설비"),
            "EE", List.of("전기", "전자", "반도체", "디스플레이"),
            "CE", List.of("건축", "토목", "인테리어", "설계")
        );

        return mappings.getOrDefault(departmentCode, Collections.emptyList());
    }

    /**
     * 매칭 점수 계산
     */
    private List<Map<String, Object>> calculateMatchScores(
            List<Map<String, Object>> jobs, Map<String, Object> userProfile) {

        List<String> userSkills = (List<String>) userProfile.getOrDefault("skills", Collections.emptyList());
        String major = (String) userProfile.getOrDefault("major", "");

        return jobs.stream()
            .peek(job -> {
                int matchScore = 0;

                // 스킬 매칭 점수
                List<String> jobSkills = (List<String>) job.getOrDefault("skills", Collections.emptyList());
                long matchedSkills = userSkills.stream()
                    .filter(skill -> jobSkills.stream().anyMatch(js -> js.toLowerCase().contains(skill.toLowerCase())))
                    .count();
                matchScore += matchedSkills * 10;

                // 전공 관련성 점수
                String requirements = (String) job.getOrDefault("requirements", "");
                if (major != null && !major.isEmpty() && requirements.contains(major)) {
                    matchScore += 20;
                }

                // OpenSearch 점수 반영
                Double searchScore = (Double) job.getOrDefault("_score", 0.0);
                matchScore += (int) (searchScore * 5);

                job.put("matchScore", Math.min(matchScore, 100));
            })
            .sorted((a, b) -> Integer.compare(
                (Integer) b.getOrDefault("matchScore", 0),
                (Integer) a.getOrDefault("matchScore", 0)))
            .toList();
    }
}
