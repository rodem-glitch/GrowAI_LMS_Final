// polytech-lms-api/src/main/java/kr/polytech/lms/ai/dto/ChatCompletionResponse.java
package kr.polytech.lms.ai.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.List;

/**
 * vLLM Chat Completion 응답 DTO
 * OpenAI API 호환 형식
 */
@Data
public class ChatCompletionResponse {

    private String id;
    private String object;
    private long created;
    private String model;
    private List<Choice> choices;
    private Usage usage;
    private String error;

    @Data
    public static class Choice {
        private int index;
        private Message message;
        @JsonProperty("finish_reason")
        private String finishReason;
    }

    @Data
    public static class Message {
        private String role;
        private String content;
    }

    @Data
    public static class Usage {
        @JsonProperty("prompt_tokens")
        private int promptTokens;
        @JsonProperty("completion_tokens")
        private int completionTokens;
        @JsonProperty("total_tokens")
        private int totalTokens;
    }

    /**
     * 응답 텍스트 추출
     */
    public String getContent() {
        if (error != null && !error.isEmpty()) {
            return "오류가 발생했습니다: " + error;
        }
        if (choices == null || choices.isEmpty()) {
            return "";
        }
        Message message = choices.get(0).getMessage();
        return message != null ? message.getContent() : "";
    }

    /**
     * 총 토큰 수
     */
    public int getTotalTokens() {
        return usage != null ? usage.getTotalTokens() : 0;
    }

    /**
     * 빈 응답 생성
     */
    public static ChatCompletionResponse empty() {
        ChatCompletionResponse response = new ChatCompletionResponse();
        response.setError("vLLM service is disabled");
        return response;
    }

    /**
     * 에러 응답 생성
     */
    public static ChatCompletionResponse error(String message) {
        ChatCompletionResponse response = new ChatCompletionResponse();
        response.setError(message);
        return response;
    }
}
