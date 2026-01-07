package kr.polytech.lms.contentsummary.service;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import kr.polytech.lms.contentsummary.client.KollusApiClient;
import kr.polytech.lms.contentsummary.client.KollusMediaDownloader;
import kr.polytech.lms.contentsummary.client.KollusProperties;
import kr.polytech.lms.contentsummary.client.SttClient;
import kr.polytech.lms.contentsummary.client.SttProperties;
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
import org.springframework.stereotype.Service;

@Service
public class ContentSummaryService {

    private final KollusApiClient kollusApiClient;
    private final KollusMediaDownloader kollusMediaDownloader;
    private final KollusProperties kollusProperties;
    private final SttClient sttClient;
    private final SttProperties sttProperties;
    private final ContentTranscriptionProperties transcriptionProperties;
    private final ContentSummaryRepository transcriptRepository;
    private final RecoContentSummaryGenerator recoContentSummaryGenerator;
    private final RecoContentRepository recoContentRepository;

    public ContentSummaryService(
        KollusApiClient kollusApiClient,
        KollusMediaDownloader kollusMediaDownloader,
        KollusProperties kollusProperties,
        SttClient sttClient,
        SttProperties sttProperties,
        ContentTranscriptionProperties transcriptionProperties,
        ContentSummaryRepository transcriptRepository,
        RecoContentSummaryGenerator recoContentSummaryGenerator,
        RecoContentRepository recoContentRepository
    ) {
        // 왜: 전사는 "외부 API + 대용량 파일" 조합이라 실패 지점이 많습니다. 의존성을 분리해두면 원인 추적이 쉬워집니다.
        this.kollusApiClient = Objects.requireNonNull(kollusApiClient);
        this.kollusMediaDownloader = Objects.requireNonNull(kollusMediaDownloader);
        this.kollusProperties = Objects.requireNonNull(kollusProperties);
        this.sttClient = Objects.requireNonNull(sttClient);
        this.sttProperties = Objects.requireNonNull(sttProperties);
        this.transcriptionProperties = Objects.requireNonNull(transcriptionProperties);
        this.transcriptRepository = Objects.requireNonNull(transcriptRepository);
        this.recoContentSummaryGenerator = Objects.requireNonNull(recoContentSummaryGenerator);
        this.recoContentRepository = Objects.requireNonNull(recoContentRepository);
    }

    public KollusWebhookIngestResponse ingestKollusWebhook(Integer siteId, String mediaContentKey, String title) {
        Integer safeSiteId = siteId == null ? 1 : siteId;
        if (mediaContentKey == null || mediaContentKey.isBlank()) {
            throw new IllegalArgumentException("mediaContentKey가 비어 있습니다.");
        }

        String mediaKey = mediaContentKey.trim();

        // 왜: 이미 요약이 TB_RECO_CONTENT에 저장되어 있으면, 전사/요약을 다시 할 필요가 없습니다(비용/시간 절감).
        if (recoContentRepository.findByLessonId(mediaKey).isPresent()) {
            return new KollusWebhookIngestResponse(mediaKey, title, "SKIPPED_SUMMARY_EXISTS");
        }

        KollusTranscript transcript = transcriptRepository
            .findBySiteIdAndMediaContentKey(safeSiteId, mediaKey)
            .orElseGet(() -> new KollusTranscript(safeSiteId, safeChannelKeyFallback(), mediaKey));

        // 왜: 이미 DONE이면 "이미 DB에 요약/전사가 저장된 상태"이므로, webhook이 중복으로 와도 다시 돌리지 않습니다.
        if ("DONE".equalsIgnoreCase(transcript.getStatus())) {
            return new KollusWebhookIngestResponse(mediaKey, title, "SKIPPED_DONE");
        }

        // 왜: 이미 처리 중이면 상태를 되돌리면(다시 PENDING) 중복 처리/경합이 생길 수 있어 그대로 둡니다.
        if ("PROCESSING".equalsIgnoreCase(transcript.getStatus())) {
            return new KollusWebhookIngestResponse(mediaKey, title, "SKIPPED_PROCESSING");
        }

        // 왜: 전사까지 끝났거나(TRANSCRIBED) 요약 재시도 상태이면, 다시 PENDING으로 되돌리면 재전사 비용이 나갑니다.
        if ("TRANSCRIBED".equalsIgnoreCase(transcript.getStatus())
            || "SUMMARY_PROCESSING".equalsIgnoreCase(transcript.getStatus())
            || "SUMMARY_FAILED".equalsIgnoreCase(transcript.getStatus())
            || "FAILED".equalsIgnoreCase(transcript.getStatus())
        ) {
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
                if (existing.isPresent()
                    && ("TRANSCRIBED".equalsIgnoreCase(existing.get().getStatus())
                    || "SUMMARY_PROCESSING".equalsIgnoreCase(existing.get().getStatus())
                    || "SUMMARY_FAILED".equalsIgnoreCase(existing.get().getStatus()))
                ) {
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

    public void processTranscriptionById(Long transcriptId) {
        if (transcriptId == null) return;
        KollusTranscript transcript = transcriptRepository.findById(transcriptId).orElse(null);
        if (transcript == null) return;

        // 왜: 워커가 이미 "PROCESSING"으로 점유한 뒤 호출합니다. 혹시라도 상태가 바뀌었으면 안전하게 중단합니다.
        if (!"PROCESSING".equalsIgnoreCase(transcript.getStatus())) return;

        doTranscribe(transcript);
    }

    public void processSummaryById(Long transcriptId) {
        if (transcriptId == null) return;
        KollusTranscript transcript = transcriptRepository.findById(transcriptId).orElse(null);
        if (transcript == null) return;

        // 왜: 워커가 "SUMMARY_PROCESSING"으로 점유한 뒤 호출합니다.
        if (!"SUMMARY_PROCESSING".equalsIgnoreCase(transcript.getStatus())) return;

        doSummarizeToRecoContent(transcript);
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

                // 왜: 이미 DONE이면 같은 영상에 대해 매번 STT 비용이 나가므로, 강제(force)가 아니면 건너뜁니다.
                String status = transcript.getStatus();
                boolean alreadyTranscribed = "TRANSCRIBED".equalsIgnoreCase(status) || "DONE".equalsIgnoreCase(status);
                if (!force && alreadyTranscribed) {
                    skipped++;
                    items.add(new RunTranscriptionItemResult(mediaKey, c.title(), "SKIPPED", "이미 전사 완료"));
                    continue;
                }

                transcript.markProcessing(c.title());
                transcriptRepository.save(transcript);

                try {
                    boolean ok = doTranscribe(transcript);
                    if (ok) {
                        processed++;
                        items.add(new RunTranscriptionItemResult(mediaKey, c.title(), "TRANSCRIBED", "전사 완료"));
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

    private boolean doTranscribe(KollusTranscript transcript) {
        Integer siteId = transcript.getSiteId() == null ? 1 : transcript.getSiteId();
        String mediaKey = transcript.getMediaContentKey();

        // 왜: 이미 요약이 TB_RECO_CONTENT에 있으면, 전사까지 다시 돌릴 필요가 없습니다.
        if (mediaKey != null && recoContentRepository.findByLessonId(mediaKey.trim()).isPresent()) {
            transcript.markSummaryDone();
            transcriptRepository.save(transcript);
            return true;
        }

        Path workDir = transcriptionProperties.tmpDir().resolve("site-" + siteId).resolve(safeFileName(mediaKey));
        Path videoFile = workDir.resolve("input.mp4");
        Path audioFile = workDir.resolve("audio.wav");

        try {
            String mediaToken = kollusApiClient.issueMediaToken(mediaKey);
            kollusMediaDownloader.downloadTo(kollusApiClient.buildDownloadUriByMediaToken(mediaToken), videoFile);

            Path sttInput = resolveSttInput(videoFile, audioFile);
            String transcriptText = sttClient.transcribe(sttInput, sttProperties.language());

            if (transcriptText == null || transcriptText.isBlank()) {
                throw new IllegalStateException("전사 결과가 비어 있습니다. (STT 응답 확인 필요)");
            }

            transcript.markTranscribed(transcriptText);
            transcriptRepository.save(transcript);
            return true;
        } catch (Exception e) {
            // 왜: 처리 실패 시에도 상태/에러를 남겨야 운영에서 추적과 재시도가 가능합니다.
            transcript.markFailed(truncateError(e, 2000));
            transcriptRepository.save(transcript);
            return false;
        } finally {
            if (!transcriptionProperties.keepTempFiles()) {
                safeDeleteDir(workDir);
            }
        }
    }

    private boolean doSummarizeToRecoContent(KollusTranscript transcript) {
        try {
            String mediaKey = transcript.getMediaContentKey();
            if (mediaKey == null || mediaKey.isBlank()) {
                throw new IllegalStateException("media_content_key가 비어 있습니다.");
            }

            // 왜: 한 번 요약을 만들어 저장했다면, 동일 영상에 대해 다시 비용을 쓰지 않습니다.
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

            String title = safeTitle(transcript.getTitle());
            RecoContentSummaryDraft draft = recoContentSummaryGenerator.generate(title, transcriptText);

            String categoryNm = safeCategory(draft.categoryNm());
            String summary = safeSummary(draft.summary());
            String keywords = joinKeywordsWithinLimit(draft.keywords(), 10, 500);

            RecoContent content = new RecoContent(categoryNm, title, summary, keywords);
            content.setLessonId(mediaKey.trim());
            recoContentRepository.save(content);

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
        // 최대 길이는 DB 저장/정책(300자) 기준으로 자릅니다.
        return trimToCodePoints(t, 300);
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

        // 왜: DB 컬럼 길이(500) 초과를 막기 위해, 길이가 넘으면 뒤에서부터 줄입니다.
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

    private Path resolveSttInput(Path videoFile, Path audioFile) {
        // 왜: ffmpeg가 있으면 wav로 바꾸고, 없으면 영상 파일(mp4)을 그대로 STT에 넣습니다.
        FfmpegAudioExtractor extractor = new FfmpegAudioExtractor();
        if (!extractor.isAvailable()) return videoFile;
        return extractor.extractWav(videoFile, audioFile);
    }

    private static void safeDeleteDir(Path dir) {
        if (dir == null) return;
        try {
            if (!Files.exists(dir)) return;
            // 왜: 임시폴더는 파일 개수가 작다는 가정(입력+오디오)이라, 간단히 역순 삭제로 정리합니다.
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
        // 왜: 현재 단계에서는 채널 키를 Kollus 설정에서 가져오지만, DB 유니크는 (site, mediaKey)이므로 필수값은 아닙니다.
        // 추후 채널 단위로 여러 개를 돌릴 경우를 대비해 저장해두는 용도입니다.
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
        // 왜: 너무 긴 메시지는 그대로 노출하면 로그/DB가 지저분해져서 적당히 자릅니다.
        return trimmed.length() > 300 ? trimmed.substring(0, 300) + "..." : trimmed;
    }
}
