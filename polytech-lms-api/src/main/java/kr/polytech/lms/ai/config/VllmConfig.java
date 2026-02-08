// polytech-lms-api/src/main/java/kr/polytech/lms/ai/config/VllmConfig.java
package kr.polytech.lms.ai.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * vLLM 서버 설정
 * Gemma 2 모델을 활용한 온프레미스 AI 추론
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "vllm")
public class VllmConfig {

    /**
     * vLLM 서버 URL
     */
    private String url = "http://localhost:8000";

    /**
     * 모델 이름 (Gemma 2)
     */
    private String model = "google/gemma-2-9b-it";

    /**
     * 활성화 여부
     */
    private boolean enabled = true;

    /**
     * 최대 토큰 수
     */
    private int maxTokens = 2048;

    /**
     * Temperature (창의성 조절)
     */
    private double temperature = 0.7;

    /**
     * Top-P 샘플링
     */
    private double topP = 0.9;

    /**
     * 요청 타임아웃 (초)
     */
    private int timeout = 60;

    /**
     * 동시 요청 최대 수
     */
    private int maxConcurrentRequests = 10;

    /**
     * 재시도 횟수
     */
    private int retryCount = 3;

    /**
     * GPU 메모리 사용률 (%)
     */
    private int gpuMemoryUtilization = 90;
}
