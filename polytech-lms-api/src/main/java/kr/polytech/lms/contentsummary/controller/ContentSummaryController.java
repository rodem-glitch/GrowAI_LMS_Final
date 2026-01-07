package kr.polytech.lms.contentsummary.controller;

import jakarta.servlet.http.HttpServletRequest;
import kr.polytech.lms.contentsummary.dto.EnqueueBackfillResponse;
import kr.polytech.lms.contentsummary.dto.KollusWebhookIngestResponse;
import kr.polytech.lms.contentsummary.dto.RunTranscriptionResponse;
import kr.polytech.lms.contentsummary.entity.KollusTranscript;
import kr.polytech.lms.contentsummary.repository.ContentSummaryRepository;
import kr.polytech.lms.contentsummary.service.ContentSummaryService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/contentsummary")
public class ContentSummaryController {

    private final ContentSummaryService contentSummaryService;
    private final ContentSummaryRepository transcriptRepository;
    private final HttpServletRequest httpServletRequest;

    public ContentSummaryController(
        ContentSummaryService contentSummaryService,
        ContentSummaryRepository transcriptRepository,
        HttpServletRequest httpServletRequest
    ) {
        // 왜: 전사 실행은 운영 리소스를 많이 쓰는 작업이라, API로 제어 가능하게 하되 기본은 로컬에서만 실행되게 막습니다.
        this.contentSummaryService = contentSummaryService;
        this.transcriptRepository = transcriptRepository;
        this.httpServletRequest = httpServletRequest;
    }

    @PostMapping("/admin/transcribe")
    public RunTranscriptionResponse runTranscription(
        @RequestHeader(name = "X-ContentSummary-Admin-Token", required = false) String adminToken,
        @RequestParam(name = "siteId", required = false) Integer siteId,
        @RequestParam(name = "limit", defaultValue = "20") int limit,
        @RequestParam(name = "force", defaultValue = "false") boolean force,
        @RequestParam(name = "keyword", required = false) String keyword
    ) {
        ensureAdminAccess(adminToken);
        return contentSummaryService.runTranscription(siteId, limit, force, keyword);
    }

    @PostMapping("/admin/enqueue/backfill")
    public EnqueueBackfillResponse enqueueBackfill(
        @RequestHeader(name = "X-ContentSummary-Admin-Token", required = false) String adminToken,
        @RequestParam(name = "siteId", required = false) Integer siteId,
        @RequestParam(name = "limit", defaultValue = "3000") int limit,
        @RequestParam(name = "keyword", required = false) String keyword
    ) {
        ensureAdminAccess(adminToken);
        return contentSummaryService.enqueueBackfill(siteId, limit, keyword);
    }

    @PostMapping("/webhooks/kollus")
    public KollusWebhookIngestResponse ingestKollusWebhook(
        @RequestHeader(name = "X-Kollus-Webhook-Token", required = false) String webhookToken,
        @RequestParam(name = "token", required = false) String webhookTokenParam,
        @RequestParam(name = "siteId", required = false) Integer siteId,
        @org.springframework.web.bind.annotation.RequestBody(required = false) com.fasterxml.jackson.databind.JsonNode body
    ) {
        ensureKollusWebhookAccess(webhookToken != null ? webhookToken : webhookTokenParam);

        if (body == null || body.isNull()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "요청 본문(JSON)이 비어 있습니다.");
        }

        String mediaContentKey = findAnyText(body,
            "/media_content_key",
            "/mediaContentKey",
            "/upload_file_key",
            "/uploadFileKey",
            "/data/media_content_key",
            "/data/upload_file_key",
            "/result/media_content_key",
            "/result/item/media_content_key",
            "/result/item/upload_file_key"
        );

        if (mediaContentKey == null || mediaContentKey.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "media_content_key(또는 upload_file_key)를 찾을 수 없습니다.");
        }

        String title = findAnyText(body,
            "/title",
            "/data/title",
            "/result/title",
            "/result/item/title"
        );

        return contentSummaryService.ingestKollusWebhook(siteId, mediaContentKey, title);
    }

    @GetMapping("/transcriptions/{mediaContentKey}")
    public KollusTranscript getTranscript(
        @RequestParam(name = "siteId", required = false) Integer siteId,
        @PathVariable("mediaContentKey") String mediaContentKey
    ) {
        Integer safeSiteId = siteId == null ? 1 : siteId;
        return transcriptRepository.findBySiteIdAndMediaContentKey(safeSiteId, mediaContentKey)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "전사 결과를 찾을 수 없습니다."));
    }

    private void ensureAdminAccess(String adminToken) {
        // 왜: 전사 실행은 비용/시간이 큰 작업이라 외부에서 무작정 호출되면 바로 장애가 납니다.
        String expected = System.getenv("CONTENTSUMMARY_ADMIN_TOKEN");

        if (expected != null && !expected.isBlank()) {
            if (adminToken == null || !expected.equals(adminToken)) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "관리자 토큰이 올바르지 않습니다.");
            }
            return;
        }

        String remoteAddr = httpServletRequest.getRemoteAddr();
        boolean isLocal = "127.0.0.1".equals(remoteAddr) || "::1".equals(remoteAddr);
        if (!isLocal) {
            throw new ResponseStatusException(
                HttpStatus.FORBIDDEN,
                "로컬에서만 실행 가능합니다. 운영에서 사용하려면 CONTENTSUMMARY_ADMIN_TOKEN을 설정해 주세요."
            );
        }
    }

    private void ensureKollusWebhookAccess(String webhookToken) {
        // 왜: webhook 엔드포인트는 외부에서 접근할 수밖에 없어서, 최소한 "공유 토큰"으로 막아야 안전합니다.
        String expected = System.getenv("KOLLUS_WEBHOOK_TOKEN");

        if (expected != null && !expected.isBlank()) {
            if (webhookToken == null || !expected.equals(webhookToken)) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Webhook 토큰이 올바르지 않습니다.");
            }
            return;
        }

        // 토큰이 없으면 개발/로컬 테스트만 허용
        String remoteAddr = httpServletRequest.getRemoteAddr();
        boolean isLocal = "127.0.0.1".equals(remoteAddr) || "::1".equals(remoteAddr);
        if (!isLocal) {
            throw new ResponseStatusException(
                HttpStatus.FORBIDDEN,
                "로컬에서만 실행 가능합니다. 운영에서 사용하려면 KOLLUS_WEBHOOK_TOKEN을 설정해 주세요."
            );
        }
    }

    private static String findAnyText(com.fasterxml.jackson.databind.JsonNode root, String... jsonPointers) {
        if (root == null) return null;
        for (String p : jsonPointers) {
            if (p == null || p.isBlank()) continue;
            com.fasterxml.jackson.databind.JsonNode node = root.at(p);
            if (node == null || node.isMissingNode() || node.isNull()) continue;
            String s = node.asText(null);
            if (s != null && !s.isBlank()) return s.trim();
        }
        return null;
    }
}
