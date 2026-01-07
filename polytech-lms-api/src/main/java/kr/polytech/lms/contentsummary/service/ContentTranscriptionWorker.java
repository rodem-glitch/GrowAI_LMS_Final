package kr.polytech.lms.contentsummary.service;

import java.util.List;
import java.util.Objects;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 왜: webhook 요청(업로드 이벤트)은 빨리 응답해야 하고, 전사/요약은 오래 걸립니다.
 * 그래서 webhook은 "큐에 넣기"만 하고, 실제 처리는 백그라운드 워커가 천천히(제어 가능하게) 수행합니다.
 */
@Component
public class ContentTranscriptionWorker {

    private final ContentSummaryWorkerProperties workerProperties;
    private final JdbcTemplate jdbcTemplate;
    private final ContentSummaryService contentSummaryService;

    public ContentTranscriptionWorker(
        ContentSummaryWorkerProperties workerProperties,
        JdbcTemplate jdbcTemplate,
        ContentSummaryService contentSummaryService
    ) {
        this.workerProperties = Objects.requireNonNull(workerProperties);
        this.jdbcTemplate = Objects.requireNonNull(jdbcTemplate);
        this.contentSummaryService = Objects.requireNonNull(contentSummaryService);
    }

    @Scheduled(fixedDelayString = "${contentsummary.worker.poll-delay-ms:30000}")
    public void poll() {
        if (!workerProperties.enabled()) return;

        List<Long> candidates = jdbcTemplate.queryForList("""
            SELECT id
            FROM TB_KOLLUS_TRANSCRIPT
            WHERE status = 'PENDING'
               OR (status = 'FAILED' AND retry_count < ? AND TIMESTAMPDIFF(SECOND, updated_at, NOW()) >= ?)
               OR (status = 'PROCESSING' AND retry_count < ? AND TIMESTAMPDIFF(SECOND, updated_at, NOW()) >= ?)
            ORDER BY id ASC
            LIMIT ?
            """,
            Long.class,
            workerProperties.maxRetries(),
            workerProperties.retryDelaySeconds(),
            workerProperties.maxRetries(),
            workerProperties.processingTimeoutSeconds(),
            workerProperties.batchSize()
        );

        for (Long id : candidates) {
            if (id == null) continue;
            boolean claimed = claim(id);
            if (!claimed) continue;
            contentSummaryService.processTranscriptionById(id);
        }
    }

    private boolean claim(Long id) {
        // 왜: 여러 워커(또는 운영에서 서버가 2대 이상)여도 같은 작업을 중복 처리하지 않도록, DB에서 먼저 "점유"합니다.
        int updated = jdbcTemplate.update("""
            UPDATE TB_KOLLUS_TRANSCRIPT
               SET status = 'PROCESSING',
                   retry_count = CASE WHEN status = 'PROCESSING' THEN retry_count + 1 ELSE retry_count END,
                   last_error = CASE WHEN status = 'PROCESSING' THEN '이전 처리(PROCESSING)가 오래 지속되어 재시도합니다.' ELSE last_error END,
                   updated_at = NOW()
             WHERE id = ?
               AND (
                 status = 'PENDING'
                 OR (status = 'FAILED' AND retry_count < ? AND TIMESTAMPDIFF(SECOND, updated_at, NOW()) >= ?)
                 OR (status = 'PROCESSING' AND retry_count < ? AND TIMESTAMPDIFF(SECOND, updated_at, NOW()) >= ?)
               )
            """,
            id,
            workerProperties.maxRetries(),
            workerProperties.retryDelaySeconds(),
            workerProperties.maxRetries(),
            workerProperties.processingTimeoutSeconds()
        );
        return updated == 1;
    }
}
