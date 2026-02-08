package kr.polytech.lms.contentsummary.service;

import java.nio.file.Path;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * 왜: 영상/오디오 파일은 크고(수백 MB) 처리 시간이 길어서, 임시파일 위치/정리 정책을 운영 환경에 맞게 바꿀 수 있어야 합니다.
 */
@ConfigurationProperties(prefix = "contentsummary.transcription")
public class ContentTranscriptionProperties {
    private Path tmpDir;
    private boolean keepTempFiles;

    public ContentTranscriptionProperties() {
        this.tmpDir = Path.of(System.getProperty("java.io.tmpdir"), "polytech-lms-api", "contentsummary");
    }

    public Path tmpDir() {
        return tmpDir;
    }

    public void setTmpDir(Path tmpDir) {
        this.tmpDir = tmpDir != null ? tmpDir : Path.of(System.getProperty("java.io.tmpdir"), "polytech-lms-api", "contentsummary");
    }

    public boolean keepTempFiles() {
        return keepTempFiles;
    }

    public void setKeepTempFiles(boolean keepTempFiles) {
        this.keepTempFiles = keepTempFiles;
    }
}
