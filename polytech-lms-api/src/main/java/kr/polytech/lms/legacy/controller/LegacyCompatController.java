// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/controller/LegacyCompatController.java
package kr.polytech.lms.legacy.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 레거시 JSP URL 호환성 컨트롤러
 * 기존 프론트엔드의 JSP 호출을 Spring Boot API로 라우팅
 */
@Slf4j
@RestController
@RequiredArgsConstructor
public class LegacyCompatController {

    /**
     * 레거시 추천 프롬프트 API
     * /mypage/new_main/reco_prompt.jsp → /api/recommendations/prompt
     */
    @GetMapping("/mypage/new_main/reco_prompt.jsp")
    public ResponseEntity<Map<String, Object>> getRecoPrompt() {
        log.debug("레거시 호출: reco_prompt.jsp");
        // TODO: 실제 추천 로직 연결
        return ResponseEntity.ok(Map.of(
            "status", "success",
            "prompt", "AI 추천 콘텐츠를 불러오는 중..."
        ));
    }

    /**
     * 레거시 추천 비디오 목록 API
     * /mypage/new_main/reco_video_list.jsp → /api/recommendations/videos
     */
    @GetMapping("/mypage/new_main/reco_video_list.jsp")
    public ResponseEntity<Map<String, Object>> getRecoVideoList() {
        log.debug("레거시 호출: reco_video_list.jsp");
        // TODO: 실제 비디오 추천 로직 연결
        return ResponseEntity.ok(Map.of(
            "status", "success",
            "videos", java.util.Collections.emptyList()
        ));
    }

    /**
     * 레거시 YouTube Shorts API
     * /api/youtube_shorts.jsp → /api/youtube/shorts
     */
    @GetMapping("/api/youtube_shorts.jsp")
    public ResponseEntity<Map<String, Object>> getYoutubeShorts(
            @RequestParam(defaultValue = "6") int maxResults) {
        log.debug("레거시 호출: youtube_shorts.jsp, maxResults={}", maxResults);
        // TODO: YouTube API 연동
        return ResponseEntity.ok(Map.of(
            "status", "success",
            "items", java.util.Collections.emptyList()
        ));
    }

    /**
     * 정적 HTML 서빙 (JSP 대체)
     */
    @GetMapping(value = {
        "/mypage/*.jsp",
        "/classroom/*.jsp",
        "/course/*.jsp",
        "/member/*.jsp"
    })
    public ResponseEntity<String> handleLegacyJsp() {
        log.warn("미구현 레거시 JSP 호출됨");
        return ResponseEntity.ok("<!-- 레거시 JSP → Spring Boot 마이그레이션 필요 -->");
    }
}
