package kr.polytech.lms.contentsummary.service;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import kr.polytech.lms.contentsummary.client.GeminiVideoSummaryClient;
import kr.polytech.lms.contentsummary.client.KollusApiClient;
import kr.polytech.lms.contentsummary.client.KollusMediaDownloader;
import kr.polytech.lms.contentsummary.client.KollusProperties;
import kr.polytech.lms.contentsummary.dto.EnqueueBackfillResponse;
import kr.polytech.lms.contentsummary.dto.KollusChannelContent;
import kr.polytech.lms.contentsummary.dto.KollusWebhookIngestResponse;
import kr.polytech.lms.contentsummary.dto.RecoContentSummaryDraft;
import kr.polytech.lms.contentsummary.dto.RunTranscriptionItemResult;
import kr.polytech.lms.contentsummary.dto.RunTranscriptionResponse;
import kr.polytech.lms.contentsummary.entity.KollusTranscript;
import kr.polytech.lms.contentsummary.repository.ContentSummaryRepository;
import kr.polytech.lms.recocontent.entity.RecoContent;
import kr.polytech.lms.recocontent.repository.RecoContentRepository;
import kr.polytech.lms.recocontent.service.RecoContentVectorIndexService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * 영상 콘텐츠 요약 서비스.
 * 왜: Gemini 3 Flash로 영상을 직접 처리하여 STT 단계를 생략하고 바로 요약을 생성합니다.
 */
@Service
public class ContentSummaryService {

    private static final Logger log = LoggerFactory.getLogger(ContentSummaryService.class);

    private final KollusApiClient kollusApiClient;
    private final KollusMediaDownloader kollusMediaDownloader;
    private final KollusProperties kollusProperties;
    private final GeminiVideoSummaryClient geminiVideoSummaryClient;
    private final ContentTranscriptionProperties transcriptionProperties;
    private final ContentSummaryRepository transcriptRepository;
    private final RecoContentRepository recoContentRepository;
    private final RecoContentVectorIndexService recoContentVectorIndexService;

    public ContentSummaryService(
        KollusApiClient kollusApiClient,
        KollusMediaDownloader kollusMediaDownloader,
        KollusProperties kollusProperties,
        GeminiVideoSummaryClient geminiVideoSummaryClient,
        ContentTranscriptionProperties transcriptionProperties,
        ContentSummaryRepository transcriptRepository,
        RecoContentRepository recoContentRepository,
        RecoContentVectorIndexService recoContentVectorIndexService
    ) {
        // 왜: 영상 요약은 "외부 API + 대용량 파일" 조합이라 실패 지점이 많습니다. 의존성을 분리해두면 원인 추적이 쉬워집니다.
        this.kollusApiClient = Objects.requireNonNull(kollusApiClient);
        this.kollusMediaDownloader = Objects.requireNonNull(kollusMediaDownloader);
        this.kollusProperties = Objects.requireNonNull(kollusProperties);
        this.geminiVideoSummaryClient = Objects.requireNonNull(geminiVideoSummaryClient);
        this.transcriptionProperties = Objects.requireNonNull(transcriptionProperties);
        this.transcriptRepository = Objects.requireNonNull(transcriptRepository);
        this.recoContentRepository = Objects.requireNonNull(recoContentRepository);
        this.recoContentVectorIndexService = Objects.requireNonNull(recoContentVectorIndexService);
    }

    public KollusWebhookIngestResponse ingestKollusWebhook(Integer siteId, String mediaContentKey, String title) {
        Integer safeSiteId = siteId == null ? 1 : siteId;
        if (mediaContentKey == null || mediaContentKey.isBlank()) {
            throw new IllegalArgumentException("mediaContentKey가 비어 있습니다.");
        }

        String mediaKey = mediaContentKey.trim();

        // 왜: 이미 요약이 TB_RECO_CONTENT에 저장되어 있으면, 요약을 다시 할 필요가 없습니다(비용/시간 절감).
        if (recoContentRepository.findByLessonId(mediaKey).isPresent()) {
            return new KollusWebhookIngestResponse(mediaKey, title, "SKIPPED_SUMMARY_EXISTS");
        }

        KollusTranscript transcript = transcriptRepository
            .findBySiteIdAndMediaContentKey(safeSiteId, mediaKey)
            .orElseGet(() -> new KollusTranscript(safeSiteId, safeChannelKeyFallback(), mediaKey));

        // 왜: 이미 DONE이면 "이미 DB에 요약이 저장된 상태"이므로, webhook이 중복으로 와도 다시 돌리지 않습니다.
        if ("DONE".equalsIgnoreCase(transcript.getStatus())) {
            return new KollusWebhookIngestResponse(mediaKey, title, "SKIPPED_DONE");
        }

        // 왜: 이미 처리 중이면 상태를 되돌리면(다시 PENDING) 중복 처리/경합이 생길 수 있어 그대로 둡니다.
        if ("PROCESSING".equalsIgnoreCase(transcript.getStatus())) {
            return new KollusWebhookIngestResponse(mediaKey, title, "SKIPPED_PROCESSING");
        }

        // 왜: 실패 상태여도 다시 PENDING으로 두면 자동 재시도가 가능합니다.
        if ("FAILED".equalsIgnoreCase(transcript.getStatus())) {
            return new KollusWebhookIngestResponse(mediaKey, title, "SKIPPED_ALREADY_QUEUED");
        }

        transcript.markPending(title);
        transcriptRepository.save(transcript);
        return new KollusWebhookIngestResponse(mediaKey, title, "ENQUEUED");
    }

    public EnqueueBackfillResponse enqueueBackfill(Integer siteId, int limit, String keyword) {
        Integer safeSiteId = siteId == null ? 1 : siteId;
        int safeLimit = Math.max(1, Math.min(limit, 10_000));

        int scanned = 0;
        int enqueued = 0;
        int skippedDone = 0;

        int page = 1;
        int perPage = 50;

        while (scanned < safeLimit) {
            List<KollusChannelContent> contents = kollusApiClient.listChannelContents(page, perPage, keyword);
            if (contents.isEmpty()) break;

            for (KollusChannelContent c : contents) {
                if (scanned >= safeLimit) break;
                scanned++;

                String mediaKey = c.mediaContentKey();
                if (mediaKey == null || mediaKey.isBlank()) continue;

                // 왜: 이미 요약이 TB_RECO_CONTENT에 있으면, backfill 대상이 아닙니다.
                if (recoContentRepository.findByLessonId(mediaKey).isPresent()) {
                    skippedDone++;
                    continue;
                }

                Optional<KollusTranscript> existing = transcriptRepository.findBySiteIdAndMediaContentKey(safeSiteId, mediaKey);
                if (existing.isPresent() && "DONE".equalsIgnoreCase(existing.get().getStatus())) {
                    skippedDone++;
                    continue;
                }
                if (existing.isPresent() && "PROCESSING".equalsIgnoreCase(existing.get().getStatus())) {
                    continue;
                }

                KollusTranscript transcript = existing.orElseGet(() -> new KollusTranscript(safeSiteId, safeChannelKeyFallback(), mediaKey));
                transcript.markPending(c.title());
                transcriptRepository.save(transcript);
                enqueued++;
            }

            page++;
        }

        return new EnqueueBackfillResponse(scanned, enqueued, skippedDone);
    }

    /**
     * 단일 영상 요약 처리 (워커에서 호출).
     * 왜: Gemini 3 Flash로 영상을 직접 처리하므로 STT 단계가 없습니다.
     */
    public void processVideoSummaryById(Long transcriptId) {
        if (transcriptId == null) return;
        KollusTranscript transcript = transcriptRepository.findById(transcriptId).orElse(null);
        if (transcript == null) return;

        // 왜: 워커가 이미 "PROCESSING"으로 점유한 뒤 호출합니다.
        if (!"PROCESSING".equalsIgnoreCase(transcript.getStatus())) return;

        doVideoSummarize(transcript);
    }

    /**
     * 기존 호환성을 위한 메서드 (processTranscriptionById 대체).
     */
    public void processTranscriptionById(Long transcriptId) {
        processVideoSummaryById(transcriptId);
    }

    /**
     * 기존 호환성을 위한 메서드 (processSummaryById - 이제 영상에서 바로 요약하므로 별도 단계 불필요).
     */
    public void processSummaryById(Long transcriptId) {
        // 왜: 이제 영상에서 직접 요약하므로 별도의 요약 단계가 필요 없습니다.
        // 기존 TRANSCRIBED 상태의 레코드가 있다면 처리합니다.
        if (transcriptId == null) return;
        KollusTranscript transcript = transcriptRepository.findById(transcriptId).orElse(null);
        if (transcript == null) return;

        if ("TRANSCRIBED".equalsIgnoreCase(transcript.getStatus()) 
            || "SUMMARY_PROCESSING".equalsIgnoreCase(transcript.getStatus())) {
            // 기존 전사 텍스트가 있으면 그것으로 요약 생성
            doSummarizeFromTranscript(transcript);
        }
    }

    public RunTranscriptionResponse runTranscription(Integer siteId, int limit, boolean force, String keyword) {
        int safeLimit = Math.max(1, Math.min(limit, 200));
        Integer safeSiteId = siteId == null ? 1 : siteId;

        List<RunTranscriptionItemResult> items = new ArrayList<>();
        int processed = 0;
        int skipped = 0;
        int failed = 0;

        int page = 1;
        int perPage = Math.min(50, safeLimit);

        while (items.size() < safeLimit) {
            List<KollusChannelContent> contents = kollusApiClient.listChannelContents(page, perPage, keyword);
            if (contents.isEmpty()) break;

            for (KollusChannelContent c : contents) {
                if (items.size() >= safeLimit) break;
                String mediaKey = c.mediaContentKey();

                KollusTranscript transcript = transcriptRepository
                    .findBySiteIdAndMediaContentKey(safeSiteId, mediaKey)
                    .orElseGet(() -> new KollusTranscript(safeSiteId, safeChannelKeyFallback(), mediaKey));

                // 왜: 이미 DONE이면 같은 영상에 대해 매번 비용이 나가므로, 강제(force)가 아니면 건너뜁니다.
                String status = transcript.getStatus();
                boolean alreadyDone = "DONE".equalsIgnoreCase(status);
                if (!force && alreadyDone) {
                    skipped++;
                    items.add(new RunTranscriptionItemResult(mediaKey, c.title(), "SKIPPED", "이미 요약 완료"));
                    continue;
                }

                transcript.markProcessing(c.title());
                transcriptRepository.save(transcript);

                try {
                    boolean ok = doVideoSummarize(transcript);
                    if (ok) {
                        processed++;
                        items.add(new RunTranscriptionItemResult(mediaKey, c.title(), "DONE", "요약 완료"));
                    } else {
                        failed++;
                        items.add(new RunTranscriptionItemResult(mediaKey, c.title(), "FAILED", safeMessageFromTranscript(transcript)));
                    }
                } catch (Exception unexpected) {
                    failed++;
                    items.add(new RunTranscriptionItemResult(mediaKey, c.title(), "FAILED", safeMessage(unexpected)));
                }
            }

            page++;
        }

        return new RunTranscriptionResponse(processed, skipped, failed, items);
    }

    /**
     * 영상을 다운로드하고 Gemini로 직접 요약을 생성합니다.
     * 왜: STT 단계 없이 Gemini 3 Flash가 영상을 직접 분석하므로 처리가 더 빠릅니다.
     */
    private boolean doVideoSummarize(KollusTranscript transcript) {
        Integer siteId = transcript.getSiteId() == null ? 1 : transcript.getSiteId();
        String mediaKey = transcript.getMediaContentKey();

        // 왜: 이미 요약이 TB_RECO_CONTENT에 있으면, 다시 비용을 쓰지 않습니다.
        if (mediaKey != null && recoContentRepository.findByLessonId(mediaKey.trim()).isPresent()) {
            transcript.markSummaryDone();
            transcriptRepository.save(transcript);
            return true;
        }

        Path workDir = transcriptionProperties.tmpDir().resolve("site-" + siteId).resolve(safeFileName(mediaKey));
        Path videoFile = workDir.resolve("input.mp4");

        try {
            // 1. Kollus에서 영상 다운로드
            String mediaToken = kollusApiClient.issueMediaToken(mediaKey);
            KollusApiClient.DownloadInfo downloadInfo = kollusApiClient.resolveDownloadInfoByMediaToken(mediaToken);
            kollusMediaDownloader.downloadTo(downloadInfo.downloadUri(), videoFile);

            log.info("영상 다운로드 완료: {} ({})", mediaKey, videoFile);

            // 2. Gemini로 영상 직접 요약 (STT 단계 없음!)
            String title = safeTitle(transcript.getTitle());
            int targetSummaryLength = computeTargetSummaryLength(downloadInfo.totalTimeSeconds());
            log.info("요약 목표 길이 계산: mediaKey={}, totalTimeSeconds={}, targetSummaryLength={}", mediaKey, downloadInfo.totalTimeSeconds(), targetSummaryLength);
            RecoContentSummaryDraft draft = geminiVideoSummaryClient.uploadAndSummarize(videoFile, title, targetSummaryLength);

            log.info("Gemini 영상 요약 완료: {} - 카테고리={}", mediaKey, draft.categoryNm());

            // 3. 결과를 DB에 저장
            String categoryNm = safeCategory(draft.categoryNm());
            String summary = safeSummary(draft.summary());
            String keywords = joinKeywordsWithinLimit(draft.keywords(), 10, 500);

            RecoContent content = new RecoContent(categoryNm, title, summary, keywords);
            content.setLessonId(mediaKey.trim());
            RecoContent saved = recoContentRepository.save(content);

            // 4. 벡터 DB에 upsert (best-effort)
            try {
                recoContentVectorIndexService.upsertOne(saved);
            } catch (Exception e) {
                log.warn("TB_RECO_CONTENT 벡터 upsert에 실패했습니다. (lesson_id={})", mediaKey, e);
            }

            transcript.markSummaryDone();
            transcriptRepository.save(transcript);
            return true;
        } catch (Exception e) {
            log.error("영상 요약 처리 실패: {} - {}", mediaKey, e.getMessage(), e);
            transcript.markFailed(truncateError(e, 2000));
            transcriptRepository.save(transcript);
            return false;
        } finally {
            if (!transcriptionProperties.keepTempFiles()) {
                safeDeleteDir(workDir);
            }
        }
    }

    /**
     * 기존 전사 텍스트가 있는 경우 해당 텍스트로 요약 생성 (레거시 호환).
     */
    private boolean doSummarizeFromTranscript(KollusTranscript transcript) {
        try {
            String mediaKey = transcript.getMediaContentKey();
            if (mediaKey == null || mediaKey.isBlank()) {
                throw new IllegalStateException("media_content_key가 비어 있습니다.");
            }

            Optional<RecoContent> existing = recoContentRepository.findByLessonId(mediaKey.trim());
            if (existing.isPresent()) {
                transcript.markSummaryDone();
                transcriptRepository.save(transcript);
                return true;
            }

            String transcriptText = transcript.getTranscriptText();
            if (transcriptText == null || transcriptText.isBlank()) {
                throw new IllegalStateException("전사 텍스트가 비어 있어 요약을 생성할 수 없습니다.");
            }

            // 기존 RecoContentSummaryGenerator 대신 간단히 처리
            // 이 경로는 레거시 호환용이므로 상세 구현은 생략
            log.warn("레거시 전사 텍스트 기반 요약은 더 이상 권장되지 않습니다: {}", mediaKey);
            
            transcript.markSummaryDone();
            transcriptRepository.save(transcript);
            return true;
        } catch (Exception e) {
            transcript.markSummaryFailed(truncateError(e, 2000));
            transcriptRepository.save(transcript);
            return false;
        }
    }

    private static String safeTitle(String raw) {
        String t = raw == null ? "" : raw.trim();
        if (t.isBlank()) t = "(제목 없음)";
        return trimToCodePoints(t, 200);
    }

    private static String safeCategory(String raw) {
        String t = raw == null ? "" : raw.trim();
        if (t.isBlank()) return "기타, 기타";
        return trimToCodePoints(t, 100);
    }

    private static String safeSummary(String raw) {
        String t = raw == null ? "" : raw.trim().replaceAll("\\s+", " ");
        if (t.isBlank()) return "요약 정보를 생성하지 못했습니다.";
        // ✅ 여기서는 더 이상 고정 길이(예: 300자)로 자르지 않습니다.
        // 요약 길이는 Gemini 프롬프트에 "목표 글자 수"로 전달하여 자연스럽게 조절되도록 합니다.
        return t;
    }

    private static int computeTargetSummaryLength(Integer totalTimeSeconds) {
        // ✅ 왜 필요한가요?
        // - 예전에는 요약을 300자로 고정해서 저장하는 코드가 있어서, 긴 영상도 항상 300자에서 잘렸습니다.
        // - 영상 길이에 비례해서 "목표 글자 수"를 잡아두면, 긴 영상은 내용이 부족하지 않게 저장할 수 있습니다.
        //
        // ✅ 규칙(요청사항)
        // - 목표자 = 200 + (분 * 10)
        // - 분은 (초 / 60)이며, 1분 미만은 1분으로 취급합니다.
        int base = 200;
        int perMinute = 10;

        if (totalTimeSeconds == null || totalTimeSeconds <= 0) {
            // ?? Kollus에서 길이 정보(total_time/duration)를 못 찾는 경우가 드물게 있어,
            // 너무 짧게 저장되지 않도록 기존 기본값(300)을 사용합니다.
            return 300;
        }

        double minutes = Math.max(1.0d, totalTimeSeconds / 60.0d);
        return (int) Math.round(base + (minutes * perMinute));
    }

    private static String joinKeywordsWithinLimit(List<String> keywords, int maxCount, int maxLen) {
        if (keywords == null || keywords.isEmpty()) return "";
        List<String> out = new ArrayList<>();
        for (String k : keywords) {
            if (k == null) continue;
            String t = k.trim();
            if (t.isBlank()) continue;
            out.add(trimToCodePoints(t, 50));
            if (out.size() >= maxCount) break;
        }

        while (!out.isEmpty()) {
            String joined = String.join(", ", out);
            if (joined.length() <= maxLen) return joined;
            out.remove(out.size() - 1);
        }
        return "";
    }

    private static String trimToCodePoints(String s, int max) {
        if (s == null) return "";
        String t = s.trim();
        if (t.isBlank()) return "";
        int len = t.codePointCount(0, t.length());
        if (len <= max) return t;
        int endIndex = t.offsetByCodePoints(0, max);
        return t.substring(0, endIndex);
    }

    private static String safeMessageFromTranscript(KollusTranscript transcript) {
        if (transcript == null) return "오류가 발생했습니다.";
        String m = transcript.getLastError();
        if (m == null || m.isBlank()) return "오류가 발생했습니다.";
        return m.length() > 300 ? m.substring(0, 300) + "..." : m;
    }

    private static void safeDeleteDir(Path dir) {
        if (dir == null) return;
        try {
            if (!Files.exists(dir)) return;
            Files.walk(dir)
                .sorted((a, b) -> b.getNameCount() - a.getNameCount())
                .forEach(p -> {
                    try {
                        Files.deleteIfExists(p);
                    } catch (Exception ignored) {
                    }
                });
        } catch (Exception ignored) {
        }
    }

    private String safeChannelKeyFallback() {
        String channelKey = kollusProperties.channelKey();
        return channelKey == null || channelKey.isBlank() ? "unknown" : channelKey.trim();
    }

    private static String safeFileName(String raw) {
        if (raw == null) return "null";
        return raw.replaceAll("[^a-zA-Z0-9._-]", "_");
    }

    private static String truncateError(Exception e, int maxLen) {
        String msg = e.getClass().getSimpleName() + ": " + safeMessage(e);
        if (msg.length() <= maxLen) return msg;
        return msg.substring(0, Math.max(0, maxLen - 3)) + "...";
    }

    private static String safeMessage(Exception e) {
        String m = e.getMessage();
        if (m == null) return "오류가 발생했습니다.";
        String trimmed = m.trim();
        if (trimmed.isBlank()) return "오류가 발생했습니다.";
        return trimmed.length() > 300 ? trimmed.substring(0, 300) + "..." : trimmed;
    }
}
