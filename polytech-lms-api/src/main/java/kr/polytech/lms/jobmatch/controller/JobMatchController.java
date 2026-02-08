// polytech-lms-api/src/main/java/kr/polytech/lms/jobmatch/controller/JobMatchController.java
package kr.polytech.lms.jobmatch.controller;

import kr.polytech.lms.jobmatch.service.JobMatchService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 채용 매칭 API 컨트롤러
 * OpenSearch 기반 채용 검색 및 추천
 */
@Slf4j
@RestController
@RequestMapping("/api/job-match")
@RequiredArgsConstructor
public class JobMatchController {

    private final JobMatchService jobMatchService;

    /**
     * 채용 공고 검색
     */
    @GetMapping("/search")
    public ResponseEntity<Map<String, Object>> searchJobs(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String region,
            @RequestParam(required = false) String occupation,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        log.info("채용 검색: keyword={}, region={}, occupation={}", keyword, region, occupation);

        Map<String, Object> result = jobMatchService.searchJobs(
            keyword, region, occupation, page, size);

        return ResponseEntity.ok(result);
    }

    /**
     * 개인 맞춤형 채용 추천
     */
    @GetMapping("/recommendations")
    public ResponseEntity<Map<String, Object>> getRecommendations(
            @RequestParam Long userId,
            @RequestParam(defaultValue = "10") int limit) {

        log.info("채용 추천 요청: userId={}", userId);

        Map<String, Object> result = jobMatchService.getPersonalizedJobRecommendations(
            userId, limit);

        return ResponseEntity.ok(result);
    }

    /**
     * 학과별 채용 추천
     */
    @GetMapping("/by-department/{deptCode}")
    public ResponseEntity<Map<String, Object>> getJobsByDepartment(
            @PathVariable String deptCode,
            @RequestParam(defaultValue = "20") int limit) {

        log.info("학과별 채용 조회: deptCode={}", deptCode);

        List<Map<String, Object>> jobs = jobMatchService.getJobsByDepartment(deptCode, limit);

        return ResponseEntity.ok(Map.of(
            "departmentCode", deptCode,
            "jobs", jobs,
            "count", jobs.size()
        ));
    }

    /**
     * 유사 채용 공고 조회
     */
    @GetMapping("/{jobId}/similar")
    public ResponseEntity<Map<String, Object>> getSimilarJobs(
            @PathVariable String jobId,
            @RequestParam(defaultValue = "5") int limit) {

        log.info("유사 채용 조회: jobId={}", jobId);

        List<Map<String, Object>> similar = jobMatchService.getSimilarJobs(jobId, limit);

        return ResponseEntity.ok(Map.of(
            "jobId", jobId,
            "similarJobs", similar,
            "count", similar.size()
        ));
    }

    /**
     * 스킬 자동완성
     */
    @GetMapping("/skills/suggest")
    public ResponseEntity<Map<String, Object>> suggestSkills(
            @RequestParam String prefix) {

        List<String> suggestions = jobMatchService.suggestSkills(prefix);

        return ResponseEntity.ok(Map.of(
            "prefix", prefix,
            "suggestions", suggestions
        ));
    }
}
