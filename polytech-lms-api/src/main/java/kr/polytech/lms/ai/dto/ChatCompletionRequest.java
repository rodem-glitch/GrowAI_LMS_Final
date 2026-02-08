// polytech-lms-api/src/main/java/kr/polytech/lms/ai/dto/ChatCompletionRequest.java
package kr.polytech.lms.ai.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Data;

import java.util.List;
import java.util.Map;

/**
 * vLLM Chat Completion 요청 DTO
 * OpenAI API 호환 형식
 */
@Data
@Builder
public class ChatCompletionRequest {

    /**
     * 모델 이름
     */
    private String model;

    /**
     * 메시지 목록
     */
    private List<Map<String, String>> messages;

    /**
     * 최대 생성 토큰 수
     */
    @JsonProperty("max_tokens")
    private int maxTokens;

    /**
     * Temperature (0.0 ~ 2.0)
     */
    private double temperature;

    /**
     * Top-P 샘플링
     */
    @JsonProperty("top_p")
    private double topP;

    /**
     * 스트리밍 여부
     */
    @Builder.Default
    private boolean stream = false;

    /**
     * 중지 시퀀스
     */
    private List<String> stop;

    /**
     * 반복 페널티
     */
    @JsonProperty("repetition_penalty")
    @Builder.Default
    private double repetitionPenalty = 1.0;

    /**
     * Frequency 페널티
     */
    @JsonProperty("frequency_penalty")
    @Builder.Default
    private double frequencyPenalty = 0.0;

    /**
     * Presence 페널티
     */
    @JsonProperty("presence_penalty")
    @Builder.Default
    private double presencePenalty = 0.0;
}
