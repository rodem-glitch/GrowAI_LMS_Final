package kr.polytech.lms.contentsummary.client;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * 왜: 전사(STT)는 외부 API를 쓰는 경우가 많고, 제공자/모델/언어가 바뀔 수 있어서 설정으로 분리합니다.
 */
@ConfigurationProperties(prefix = "stt")
public class SttProperties {

    private String provider;
    private String language;
    private Google google;
    private Duration httpTimeout;

    public SttProperties() {
    }

    public String provider() {
        return provider;
    }

    public void setProvider(String provider) {
        this.provider = (provider == null || provider.isBlank()) ? "google" : provider.trim();
    }

    public String language() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = (language == null || language.isBlank()) ? "ko" : language.trim();
    }

    public Google google() {
        return google;
    }

    public void setGoogle(Google google) {
        this.google = google == null ? new Google() : google;
    }

    public Duration httpTimeout() {
        return httpTimeout;
    }

    public void setHttpTimeout(Duration httpTimeout) {
        this.httpTimeout = safeTimeout(httpTimeout, Duration.ofMinutes(5));
    }

    private static Duration safeTimeout(Duration configured, Duration fallback) {
        if (configured == null) return fallback;
        if (configured.isZero() || configured.isNegative()) return fallback;
        return configured;
    }

    public static class Google {

        private String projectId;
        private String location;
        private String recognizerId;
        private String gcsBucket;
        private String gcsPrefix;
        private boolean keepUploadedFiles;
        private boolean enableAutomaticPunctuation = true;
        private Duration pollingInterval;
        private Duration pollingTimeout;
        private String model;

        public Google() {
        }

        public String projectId() {
            return projectId;
        }

        public void setProjectId(String projectId) {
            this.projectId = projectId;
        }

        public String location() {
            return location;
        }

        public void setLocation(String location) {
            this.location = (location == null || location.isBlank()) ? "global" : location.trim();
        }

        public String recognizerId() {
            return recognizerId;
        }

        public void setRecognizerId(String recognizerId) {
            this.recognizerId = (recognizerId == null || recognizerId.isBlank()) ? "_" : recognizerId.trim();
        }

        public String gcsBucket() {
            return gcsBucket;
        }

        public void setGcsBucket(String gcsBucket) {
            this.gcsBucket = gcsBucket;
        }

        public String gcsPrefix() {
            return gcsPrefix;
        }

        public void setGcsPrefix(String gcsPrefix) {
            this.gcsPrefix = normalizeGcsPrefix(gcsPrefix, "contentsummary/stt");
        }

        public boolean keepUploadedFiles() {
            return keepUploadedFiles;
        }

        public void setKeepUploadedFiles(boolean keepUploadedFiles) {
            this.keepUploadedFiles = keepUploadedFiles;
        }

        public boolean enableAutomaticPunctuation() {
            return enableAutomaticPunctuation;
        }

        public void setEnableAutomaticPunctuation(boolean enableAutomaticPunctuation) {
            this.enableAutomaticPunctuation = enableAutomaticPunctuation;
        }

        public Duration pollingInterval() {
            return pollingInterval;
        }

        public void setPollingInterval(Duration pollingInterval) {
            this.pollingInterval = safeTimeout(pollingInterval, Duration.ofSeconds(2));
        }

        public Duration pollingTimeout() {
            return pollingTimeout;
        }

        public void setPollingTimeout(Duration pollingTimeout) {
            this.pollingTimeout = safeTimeout(pollingTimeout, Duration.ofHours(2));
        }

        public String model() {
            return model;
        }

        public void setModel(String model) {
            this.model = (model == null || model.isBlank()) ? "latest_long" : model.trim();
        }

        private static String normalizeGcsPrefix(String prefix, String defaultValue) {
            if (prefix == null || prefix.isBlank()) return defaultValue;
            String trimmed = prefix.trim();
            while (trimmed.startsWith("/")) trimmed = trimmed.substring(1);
            while (trimmed.endsWith("/")) trimmed = trimmed.substring(0, trimmed.length() - 1);
            return trimmed.isBlank() ? defaultValue : trimmed;
        }

        private static Duration safeTimeout(Duration configured, Duration fallback) {
            if (configured == null) return fallback;
            if (configured.isZero() || configured.isNegative()) return fallback;
            return configured;
        }
    }
}
