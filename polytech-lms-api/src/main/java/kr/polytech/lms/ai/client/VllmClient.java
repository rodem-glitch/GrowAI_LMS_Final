// polytech-lms-api/src/main/java/kr/polytech/lms/ai/client/VllmClient.java
package kr.polytech.lms.ai.client;

import kr.polytech.lms.ai.config.VllmConfig;
import kr.polytech.lms.ai.dto.ChatCompletionRequest;
import kr.polytech.lms.ai.dto.ChatCompletionResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Semaphore;

/**
 * vLLM API 클라이언트
 * OpenAI 호환 API를 통한 Gemma 2 모델 추론
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class VllmClient {

    private final VllmConfig config;
    private final RestTemplate restTemplate = new RestTemplate();
    private Semaphore concurrencyLimiter;

    /**
     * 동시성 제한 초기화
     */
    private Semaphore getConcurrencyLimiter() {
        if (concurrencyLimiter == null) {
            concurrencyLimiter = new Semaphore(config.getMaxConcurrentRequests());
        }
        return concurrencyLimiter;
    }

    /**
     * Chat Completion API 호출
     */
    public ChatCompletionResponse chatCompletion(List<Map<String, String>> messages) {
        return chatCompletion(messages, null);
    }

    /**
     * Chat Completion API 호출 (시스템 프롬프트 포함)
     */
    public ChatCompletionResponse chatCompletion(List<Map<String, String>> messages, String systemPrompt) {
        if (!config.isEnabled()) {
            log.debug("vLLM 비활성화 상태");
            return ChatCompletionResponse.empty();
        }

        try {
            getConcurrencyLimiter().acquire();

            // 시스템 프롬프트 추가
            if (systemPrompt != null && !systemPrompt.isEmpty()) {
                messages.add(0, Map.of("role", "system", "content", systemPrompt));
            }

            ChatCompletionRequest request = ChatCompletionRequest.builder()
                .model(config.getModel())
                .messages(messages)
                .maxTokens(config.getMaxTokens())
                .temperature(config.getTemperature())
                .topP(config.getTopP())
                .build();

            String url = config.getUrl() + "/v1/chat/completions";

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<ChatCompletionRequest> entity = new HttpEntity<>(request, headers);

            long startTime = System.currentTimeMillis();
            ResponseEntity<ChatCompletionResponse> response = restTemplate.exchange(
                url, HttpMethod.POST, entity, ChatCompletionResponse.class);

            long duration = System.currentTimeMillis() - startTime;
            log.info("vLLM 응답 시간: {}ms, 토큰: {}", duration,
                response.getBody() != null ? response.getBody().getTotalTokens() : 0);

            return response.getBody();

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.error("vLLM 요청 중단: {}", e.getMessage());
            return ChatCompletionResponse.error("Request interrupted");
        } catch (Exception e) {
            log.error("vLLM API 호출 실패: {}", e.getMessage());
            return ChatCompletionResponse.error(e.getMessage());
        } finally {
            getConcurrencyLimiter().release();
        }
    }

    /**
     * 텍스트 생성 (간단 버전)
     */
    public String generate(String prompt) {
        List<Map<String, String>> messages = List.of(
            Map.of("role", "user", "content", prompt)
        );
        ChatCompletionResponse response = chatCompletion(messages);
        return response.getContent();
    }

    /**
     * 학습 도우미 응답 생성
     */
    public String generateLearningAssistance(String question, String context) {
        String systemPrompt = """
            당신은 한국폴리텍대학의 AI 학습 도우미입니다.
            학생들의 질문에 친절하고 정확하게 답변해주세요.
            기술 용어는 쉽게 풀어서 설명하고, 실습 예제를 포함해주세요.
            답변은 한국어로 작성하세요.
            """;

        String userPrompt = String.format("""
            [관련 학습 자료]
            %s

            [학생 질문]
            %s

            위 자료를 참고하여 학생의 질문에 답변해주세요.
            """, context, question);

        List<Map<String, String>> messages = List.of(
            Map.of("role", "user", "content", userPrompt)
        );

        ChatCompletionResponse response = chatCompletion(messages, systemPrompt);
        return response.getContent();
    }

    /**
     * 서버 상태 확인
     */
    public boolean isHealthy() {
        if (!config.isEnabled()) {
            return false;
        }

        try {
            String url = config.getUrl() + "/health";
            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            log.debug("vLLM 헬스체크 실패: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 모델 정보 조회
     */
    public Map<String, Object> getModelInfo() {
        try {
            String url = config.getUrl() + "/v1/models";
            ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);
            return response.getBody();
        } catch (Exception e) {
            log.error("모델 정보 조회 실패: {}", e.getMessage());
            return Map.of("error", e.getMessage());
        }
    }
}
