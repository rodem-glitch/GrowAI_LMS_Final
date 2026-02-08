package kr.polytech.lms.contentsummary.service;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * 왜: 전사/요약은 비용과 시간이 큰 작업이라, 운영에서 "자동 실행 여부/속도"를 환경변수로 제어해야 안전합니다.
 */
@ConfigurationProperties(prefix = "contentsummary.worker")
public class ContentSummaryWorkerProperties {

    private boolean enabled;
    private long pollDelayMs;
    private int batchSize;
    private int maxRetries;
    private int retryDelaySeconds;
    private int processingTimeoutSeconds;

    public ContentSummaryWorkerProperties() {
    }

    public boolean enabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public long pollDelayMs() {
        return pollDelayMs;
    }

    public void setPollDelayMs(long pollDelayMs) {
        this.pollDelayMs = pollDelayMs <= 0 ? 30_000L : pollDelayMs;
    }

    public int batchSize() {
        return batchSize;
    }

    public void setBatchSize(int batchSize) {
        this.batchSize = batchSize <= 0 ? 3 : Math.min(batchSize, 50);
    }

    public int maxRetries() {
        return maxRetries;
    }

    public void setMaxRetries(int maxRetries) {
        this.maxRetries = maxRetries < 0 ? 0 : maxRetries;
    }

    public int retryDelaySeconds() {
        return retryDelaySeconds;
    }

    public void setRetryDelaySeconds(int retryDelaySeconds) {
        this.retryDelaySeconds = retryDelaySeconds < 0 ? 0 : retryDelaySeconds;
    }

    public int processingTimeoutSeconds() {
        return processingTimeoutSeconds;
    }

    public void setProcessingTimeoutSeconds(int processingTimeoutSeconds) {
        this.processingTimeoutSeconds = processingTimeoutSeconds <= 0 ? 7200 : processingTimeoutSeconds;
    }
}
