// polytech-lms-api/src/main/java/kr/polytech/lms/gcp/controller/GcpController.java
package kr.polytech.lms.gcp.controller;

import kr.polytech.lms.gcp.service.*;
import kr.polytech.lms.security.error.ExternalServiceException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * GCP 서비스 통합 API 컨트롤러
 * - Vertex AI (aiplatform.googleapis.com)
 * - BigQuery (bigquery.googleapis.com)
 * - Text-to-Speech (texttospeech.googleapis.com)
 * - Speech-to-Text (speech.googleapis.com)
 */
@Slf4j
@RestController
@RequestMapping("/api/gcp")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class GcpController {

    private final VertexAiService vertexAiService;
    private final BigQueryService bigQueryService;
    private final TextToSpeechService textToSpeechService;
    private final SpeechToTextService speechToTextService;

    // ==================== Vertex AI API ====================

    /**
     * 텍스트 임베딩 생성
     */
    @PostMapping("/vertex-ai/embedding")
    public ResponseEntity<Map<String, Object>> generateEmbedding(@RequestBody Map<String, String> request) {
        String text = request.get("text");
        if (text == null || text.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "텍스트를 입력해주세요.", "timestamp", LocalDateTime.now().toString()));
        }

        try {
            List<Float> embedding = vertexAiService.generateEmbedding(text);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("dimensions", embedding.size(), "embedding", embedding),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Vertex AI 임베딩 생성 실패: {}", e.getMessage(), e);
            throw new ExternalServiceException("VertexAI", "AI_003", "AI 서비스 연결에 실패했습니다.", e);
        }
    }

    /**
     * 배치 임베딩 생성
     */
    @PostMapping("/vertex-ai/embeddings/batch")
    public ResponseEntity<Map<String, Object>> generateBatchEmbeddings(@RequestBody Map<String, List<String>> request) {
        List<String> texts = request.get("texts");
        if (texts == null || texts.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "텍스트 목록을 입력해주세요.", "timestamp", LocalDateTime.now().toString()));
        }

        try {
            List<List<Float>> embeddings = vertexAiService.generateBatchEmbeddings(texts);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("count", embeddings.size(), "embeddings", embeddings),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Vertex AI 배치 임베딩 실패: {}", e.getMessage(), e);
            throw new ExternalServiceException("VertexAI", "AI_003", "AI 서비스 연결에 실패했습니다.", e);
        }
    }

    /**
     * RAG 질의응답
     */
    @PostMapping("/vertex-ai/rag")
    public ResponseEntity<Map<String, Object>> ragQuery(@RequestBody Map<String, Object> request) {
        String query = (String) request.get("query");
        if (query == null || query.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "질의를 입력해주세요.", "timestamp", LocalDateTime.now().toString()));
        }

        @SuppressWarnings("unchecked")
        List<String> contexts = (List<String>) request.getOrDefault("contexts", List.of());

        try {
            Map<String, Object> result = vertexAiService.ragQuery(query, contexts);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", result, "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Vertex AI RAG 질의 실패: {}", e.getMessage(), e);
            throw new ExternalServiceException("VertexAI", "AI_003", "AI 서비스 연결에 실패했습니다.", e);
        }
    }

    /**
     * 문서 요약
     */
    @PostMapping("/vertex-ai/summarize")
    public ResponseEntity<Map<String, Object>> summarize(@RequestBody Map<String, Object> request) {
        String content = (String) request.get("content");
        if (content == null || content.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "요약할 내용을 입력해주세요.", "timestamp", LocalDateTime.now().toString()));
        }
        int maxLength = ((Number) request.getOrDefault("maxLength", 500)).intValue();

        try {
            String summary = vertexAiService.summarizeDocument(content, maxLength);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("summary", summary,
                    "originalLength", content.length(), "summaryLength", summary.length()),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("Vertex AI 문서 요약 실패: {}", e.getMessage(), e);
            throw new ExternalServiceException("VertexAI", "AI_003", "AI 서비스 연결에 실패했습니다.", e);
        }
    }

    /**
     * 유사도 계산
     */
    @PostMapping("/vertex-ai/similarity")
    public ResponseEntity<Map<String, Object>> calculateSimilarity(@RequestBody Map<String, Object> request) {
        if (request.get("embedding1") == null || request.get("embedding2") == null) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "두 임베딩 벡터를 입력해주세요.", "timestamp", LocalDateTime.now().toString()));
        }

        try {
            @SuppressWarnings("unchecked")
            List<Double> emb1Double = (List<Double>) request.get("embedding1");
            @SuppressWarnings("unchecked")
            List<Double> emb2Double = (List<Double>) request.get("embedding2");

            List<Float> embedding1 = emb1Double.stream().map(Double::floatValue).toList();
            List<Float> embedding2 = emb2Double.stream().map(Double::floatValue).toList();

            double similarity = vertexAiService.calculateSimilarity(embedding1, embedding2);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", Map.of("similarity", similarity),
                "timestamp", LocalDateTime.now().toString()));
        } catch (ExternalServiceException e) {
            throw e;
        } catch (Exception e) {
            log.error("유사도 계산 실패: {}", e.getMessage(), e);
            throw new ExternalServiceException("VertexAI", "AI_003", "AI 서비스 연결에 실패했습니다.", e);
        }
    }

    // ==================== BigQuery API ====================

    /**
     * SQL 쿼리 실행
     */
    @PostMapping("/bigquery/query")
    public ResponseEntity<Map<String, Object>> executeQuery(@RequestBody Map<String, String> request) {
        String sql = request.get("sql");
        if (sql == null || sql.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "SQL 쿼리를 입력해주세요.", "timestamp", LocalDateTime.now().toString()));
        }

        try {
            List<Map<String, Object>> results = bigQueryService.executeQuery(sql);
            return ResponseEntity.ok(Map.of(
                "success", true, "data", Map.of("rowCount", results.size(), "rows", results),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("BigQuery 쿼리 실행 실패: {}", e.getMessage(), e);
            throw new ExternalServiceException("BigQuery", "SERVER_001", "데이터 조회에 실패했습니다.", e);
        }
    }

    /**
     * 학습 진도 통계 (SFR-006)
     */
    @GetMapping("/bigquery/stats/progress/{courseCode}")
    public ResponseEntity<Map<String, Object>> getLearningProgressStats(@PathVariable String courseCode) {
        try {
            Map<String, Object> stats = bigQueryService.getLearningProgressStats(courseCode);
            return ResponseEntity.ok(Map.of("success", true, "data", stats,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("학습 진도 통계 조회 실패: courseCode={}", courseCode, e);
            throw new ExternalServiceException("BigQuery", "SERVER_001", "통계 데이터 조회에 실패했습니다.", e);
        }
    }

    /**
     * 출석률 통계
     */
    @GetMapping("/bigquery/stats/attendance/{courseCode}")
    public ResponseEntity<Map<String, Object>> getAttendanceStats(@PathVariable String courseCode) {
        try {
            Map<String, Object> stats = bigQueryService.getAttendanceStats(courseCode);
            return ResponseEntity.ok(Map.of("success", true, "data", stats,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("출석률 통계 조회 실패: courseCode={}", courseCode, e);
            throw new ExternalServiceException("BigQuery", "SERVER_001", "통계 데이터 조회에 실패했습니다.", e);
        }
    }

    /**
     * 성적 분포 통계
     */
    @GetMapping("/bigquery/stats/grades/{courseCode}")
    public ResponseEntity<Map<String, Object>> getGradeDistribution(@PathVariable String courseCode) {
        try {
            Map<String, Object> stats = bigQueryService.getGradeDistribution(courseCode);
            return ResponseEntity.ok(Map.of("success", true, "data", stats,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("성적 분포 조회 실패: courseCode={}", courseCode, e);
            throw new ExternalServiceException("BigQuery", "SERVER_001", "통계 데이터 조회에 실패했습니다.", e);
        }
    }

    /**
     * 학습 행동 분석
     */
    @GetMapping("/bigquery/stats/behavior/{memberKey}")
    public ResponseEntity<Map<String, Object>> getLearningBehavior(@PathVariable String memberKey) {
        try {
            Map<String, Object> stats = bigQueryService.getLearningBehaviorAnalysis(memberKey);
            return ResponseEntity.ok(Map.of("success", true, "data", stats,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("학습 행동 분석 실패: memberKey={}", memberKey, e);
            throw new ExternalServiceException("BigQuery", "SERVER_001", "통계 데이터 조회에 실패했습니다.", e);
        }
    }

    /**
     * 과정별 비교 통계
     */
    @GetMapping("/bigquery/stats/comparison")
    public ResponseEntity<Map<String, Object>> getCourseComparison() {
        try {
            List<Map<String, Object>> stats = bigQueryService.getCourseComparison();
            return ResponseEntity.ok(Map.of("success", true, "data", stats,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("과정 비교 통계 조회 실패", e);
            throw new ExternalServiceException("BigQuery", "SERVER_001", "통계 데이터 조회에 실패했습니다.", e);
        }
    }

    /**
     * 취업 통계
     */
    @GetMapping("/bigquery/stats/employment/{deptCode}")
    public ResponseEntity<Map<String, Object>> getEmploymentStats(@PathVariable String deptCode) {
        try {
            Map<String, Object> stats = bigQueryService.getEmploymentStats(deptCode);
            return ResponseEntity.ok(Map.of("success", true, "data", stats,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("취업 통계 조회 실패: deptCode={}", deptCode, e);
            throw new ExternalServiceException("BigQuery", "SERVER_001", "통계 데이터 조회에 실패했습니다.", e);
        }
    }

    /**
     * 대시보드 요약
     */
    @GetMapping("/bigquery/dashboard")
    public ResponseEntity<Map<String, Object>> getDashboardSummary() {
        try {
            Map<String, Object> summary = bigQueryService.getDashboardSummary();
            return ResponseEntity.ok(Map.of("success", true, "data", summary,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("대시보드 요약 조회 실패", e);
            throw new ExternalServiceException("BigQuery", "SERVER_001", "대시보드 데이터 조회에 실패했습니다.", e);
        }
    }

    // ==================== Text-to-Speech API ====================

    /**
     * 텍스트를 음성으로 변환
     */
    @PostMapping("/tts/synthesize")
    public ResponseEntity<Map<String, Object>> synthesizeSpeech(@RequestBody Map<String, Object> request) {
        String text = (String) request.get("text");
        if (text == null || text.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "변환할 텍스트를 입력해주세요.", "timestamp", LocalDateTime.now().toString()));
        }
        String voiceName = (String) request.get("voiceName");
        String languageCode = (String) request.get("languageCode");

        try {
            Map<String, Object> result = textToSpeechService.synthesizeSpeech(text, voiceName, languageCode);
            return ResponseEntity.ok(Map.of("success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("TTS 음성 합성 실패: {}", e.getMessage(), e);
            throw new ExternalServiceException("TextToSpeech", "SERVER_001", "음성 합성에 실패했습니다.", e);
        }
    }

    /**
     * SSML 음성 합성
     */
    @PostMapping("/tts/synthesize-ssml")
    public ResponseEntity<Map<String, Object>> synthesizeSsml(@RequestBody Map<String, Object> request) {
        String ssml = (String) request.get("ssml");
        if (ssml == null || ssml.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "SSML 내용을 입력해주세요.", "timestamp", LocalDateTime.now().toString()));
        }
        String voiceName = (String) request.get("voiceName");
        String languageCode = (String) request.get("languageCode");

        try {
            Map<String, Object> result = textToSpeechService.synthesizeSsml(ssml, voiceName, languageCode);
            return ResponseEntity.ok(Map.of("success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("SSML 음성 합성 실패: {}", e.getMessage(), e);
            throw new ExternalServiceException("TextToSpeech", "SERVER_001", "음성 합성에 실패했습니다.", e);
        }
    }

    /**
     * 사용 가능한 음성 목록
     */
    @GetMapping("/tts/voices")
    public ResponseEntity<Map<String, Object>> listVoices(
            @RequestParam(required = false) String languageCode) {
        try {
            List<Map<String, Object>> voices = textToSpeechService.listVoices(languageCode);
            return ResponseEntity.ok(Map.of("success", true, "data", Map.of("voices", voices),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("TTS 음성 목록 조회 실패: {}", e.getMessage(), e);
            throw new ExternalServiceException("TextToSpeech", "SERVER_001", "음성 목록 조회에 실패했습니다.", e);
        }
    }

    // ==================== Speech-to-Text API ====================

    /**
     * 음성을 텍스트로 변환
     */
    @PostMapping("/stt/recognize")
    public ResponseEntity<Map<String, Object>> recognizeSpeech(
            @RequestParam("audio") MultipartFile audio,
            @RequestParam(required = false) String languageCode) {
        if (audio == null || audio.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "FILE_001",
                "message", "오디오 파일을 업로드해주세요.", "timestamp", LocalDateTime.now().toString()));
        }

        try {
            Map<String, Object> result = speechToTextService.recognizeSpeech(audio.getBytes(), languageCode, 0);
            return ResponseEntity.ok(Map.of("success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("STT 음성 인식 실패: {}", e.getMessage(), e);
            throw new ExternalServiceException("SpeechToText", "SERVER_001", "음성 인식에 실패했습니다.", e);
        }
    }

    /**
     * Base64 오디오 음성 인식
     */
    @PostMapping("/stt/recognize-base64")
    public ResponseEntity<Map<String, Object>> recognizeSpeechBase64(@RequestBody Map<String, Object> request) {
        String audioBase64 = (String) request.get("audio");
        if (audioBase64 == null || audioBase64.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "오디오 데이터를 입력해주세요.", "timestamp", LocalDateTime.now().toString()));
        }
        String languageCode = (String) request.get("languageCode");
        int sampleRate = ((Number) request.getOrDefault("sampleRate", 16000)).intValue();

        try {
            byte[] audioData = java.util.Base64.getDecoder().decode(audioBase64);
            Map<String, Object> result = speechToTextService.recognizeSpeech(audioData, languageCode, sampleRate);
            return ResponseEntity.ok(Map.of("success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_001",
                "message", "올바른 Base64 형식이 아닙니다.", "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("STT Base64 음성 인식 실패: {}", e.getMessage(), e);
            throw new ExternalServiceException("SpeechToText", "SERVER_001", "음성 인식에 실패했습니다.", e);
        }
    }

    /**
     * 장시간 음성 인식 시작
     */
    @PostMapping("/stt/long-running")
    public ResponseEntity<Map<String, Object>> recognizeLongAudio(@RequestBody Map<String, String> request) {
        String gcsUri = request.get("gcsUri");
        if (gcsUri == null || gcsUri.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false, "errorCode", "VALIDATION_002",
                "message", "GCS URI를 입력해주세요.", "timestamp", LocalDateTime.now().toString()));
        }
        String languageCode = request.get("languageCode");

        try {
            Map<String, Object> result = speechToTextService.recognizeLongAudio(gcsUri, languageCode);
            return ResponseEntity.ok(Map.of("success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("장시간 음성 인식 실패: {}", e.getMessage(), e);
            throw new ExternalServiceException("SpeechToText", "SERVER_001", "음성 인식에 실패했습니다.", e);
        }
    }

    /**
     * 장시간 음성 인식 결과 조회
     */
    @GetMapping("/stt/long-running/{operationName}")
    public ResponseEntity<Map<String, Object>> getLongAudioResult(@PathVariable String operationName) {
        try {
            Map<String, Object> result = speechToTextService.getLongAudioResult(operationName);
            return ResponseEntity.ok(Map.of("success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("장시간 음성 인식 결과 조회 실패: {}", operationName, e);
            throw new ExternalServiceException("SpeechToText", "SERVER_001", "결과 조회에 실패했습니다.", e);
        }
    }

    /**
     * 스트리밍 설정 정보
     */
    @GetMapping("/stt/streaming-config")
    public ResponseEntity<Map<String, Object>> getStreamingConfig() {
        try {
            Map<String, Object> config = speechToTextService.getStreamingConfig();
            return ResponseEntity.ok(Map.of("success", true, "data", Map.of("config", config),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("스트리밍 설정 조회 실패: {}", e.getMessage(), e);
            throw new ExternalServiceException("SpeechToText", "SERVER_001", "설정 조회에 실패했습니다.", e);
        }
    }

    // ==================== 헬스체크 ====================

    /**
     * 전체 GCP 서비스 상태
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        try {
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of(
                    "status", "UP",
                    "services", Map.of(
                        "vertexAi", vertexAiService.healthCheck(),
                        "bigQuery", bigQueryService.healthCheck(),
                        "textToSpeech", textToSpeechService.healthCheck(),
                        "speechToText", speechToTextService.healthCheck())),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("GCP 헬스체크 실패: {}", e.getMessage());
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("status", "DEGRADED"),
                "timestamp", LocalDateTime.now().toString()));
        }
    }
}
