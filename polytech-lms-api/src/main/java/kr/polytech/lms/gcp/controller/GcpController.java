// polytech-lms-api/src/main/java/kr/polytech/lms/gcp/controller/GcpController.java
package kr.polytech.lms.gcp.controller;

import kr.polytech.lms.gcp.service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
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
        List<Float> embedding = vertexAiService.generateEmbedding(text);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "dimensions", embedding.size(),
            "embedding", embedding
        ));
    }

    /**
     * 배치 임베딩 생성
     */
    @PostMapping("/vertex-ai/embeddings/batch")
    public ResponseEntity<Map<String, Object>> generateBatchEmbeddings(@RequestBody Map<String, List<String>> request) {
        List<String> texts = request.get("texts");
        List<List<Float>> embeddings = vertexAiService.generateBatchEmbeddings(texts);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "count", embeddings.size(),
            "embeddings", embeddings
        ));
    }

    /**
     * RAG 질의응답
     */
    @PostMapping("/vertex-ai/rag")
    public ResponseEntity<Map<String, Object>> ragQuery(@RequestBody Map<String, Object> request) {
        String query = (String) request.get("query");
        @SuppressWarnings("unchecked")
        List<String> contexts = (List<String>) request.getOrDefault("contexts", List.of());

        Map<String, Object> result = vertexAiService.ragQuery(query, contexts);
        return ResponseEntity.ok(result);
    }

    /**
     * 문서 요약
     */
    @PostMapping("/vertex-ai/summarize")
    public ResponseEntity<Map<String, Object>> summarize(@RequestBody Map<String, Object> request) {
        String content = (String) request.get("content");
        int maxLength = ((Number) request.getOrDefault("maxLength", 500)).intValue();

        String summary = vertexAiService.summarizeDocument(content, maxLength);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "summary", summary,
            "originalLength", content.length(),
            "summaryLength", summary.length()
        ));
    }

    /**
     * 유사도 계산
     */
    @PostMapping("/vertex-ai/similarity")
    public ResponseEntity<Map<String, Object>> calculateSimilarity(@RequestBody Map<String, Object> request) {
        @SuppressWarnings("unchecked")
        List<Double> emb1Double = (List<Double>) request.get("embedding1");
        @SuppressWarnings("unchecked")
        List<Double> emb2Double = (List<Double>) request.get("embedding2");

        List<Float> embedding1 = emb1Double.stream().map(Double::floatValue).toList();
        List<Float> embedding2 = emb2Double.stream().map(Double::floatValue).toList();

        double similarity = vertexAiService.calculateSimilarity(embedding1, embedding2);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "similarity", similarity
        ));
    }

    // ==================== BigQuery API ====================

    /**
     * SQL 쿼리 실행
     */
    @PostMapping("/bigquery/query")
    public ResponseEntity<Map<String, Object>> executeQuery(@RequestBody Map<String, String> request) {
        String sql = request.get("sql");
        List<Map<String, Object>> results = bigQueryService.executeQuery(sql);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "rowCount", results.size(),
            "data", results
        ));
    }

    /**
     * 학습 진도 통계 (SFR-006)
     */
    @GetMapping("/bigquery/stats/progress/{courseCode}")
    public ResponseEntity<Map<String, Object>> getLearningProgressStats(@PathVariable String courseCode) {
        Map<String, Object> stats = bigQueryService.getLearningProgressStats(courseCode);
        return ResponseEntity.ok(Map.of("success", true, "data", stats));
    }

    /**
     * 출석률 통계
     */
    @GetMapping("/bigquery/stats/attendance/{courseCode}")
    public ResponseEntity<Map<String, Object>> getAttendanceStats(@PathVariable String courseCode) {
        Map<String, Object> stats = bigQueryService.getAttendanceStats(courseCode);
        return ResponseEntity.ok(Map.of("success", true, "data", stats));
    }

    /**
     * 성적 분포 통계
     */
    @GetMapping("/bigquery/stats/grades/{courseCode}")
    public ResponseEntity<Map<String, Object>> getGradeDistribution(@PathVariable String courseCode) {
        Map<String, Object> stats = bigQueryService.getGradeDistribution(courseCode);
        return ResponseEntity.ok(Map.of("success", true, "data", stats));
    }

    /**
     * 학습 행동 분석
     */
    @GetMapping("/bigquery/stats/behavior/{memberKey}")
    public ResponseEntity<Map<String, Object>> getLearningBehavior(@PathVariable String memberKey) {
        Map<String, Object> stats = bigQueryService.getLearningBehaviorAnalysis(memberKey);
        return ResponseEntity.ok(Map.of("success", true, "data", stats));
    }

    /**
     * 과정별 비교 통계
     */
    @GetMapping("/bigquery/stats/comparison")
    public ResponseEntity<Map<String, Object>> getCourseComparison() {
        List<Map<String, Object>> stats = bigQueryService.getCourseComparison();
        return ResponseEntity.ok(Map.of("success", true, "data", stats));
    }

    /**
     * 취업 통계
     */
    @GetMapping("/bigquery/stats/employment/{deptCode}")
    public ResponseEntity<Map<String, Object>> getEmploymentStats(@PathVariable String deptCode) {
        Map<String, Object> stats = bigQueryService.getEmploymentStats(deptCode);
        return ResponseEntity.ok(Map.of("success", true, "data", stats));
    }

    /**
     * 대시보드 요약
     */
    @GetMapping("/bigquery/dashboard")
    public ResponseEntity<Map<String, Object>> getDashboardSummary() {
        Map<String, Object> summary = bigQueryService.getDashboardSummary();
        return ResponseEntity.ok(Map.of("success", true, "data", summary));
    }

    // ==================== Text-to-Speech API ====================

    /**
     * 텍스트를 음성으로 변환
     */
    @PostMapping("/tts/synthesize")
    public ResponseEntity<Map<String, Object>> synthesizeSpeech(@RequestBody Map<String, Object> request) {
        String text = (String) request.get("text");
        String voiceName = (String) request.get("voiceName");
        String languageCode = (String) request.get("languageCode");

        Map<String, Object> result = textToSpeechService.synthesizeSpeech(text, voiceName, languageCode);
        return ResponseEntity.ok(result);
    }

    /**
     * SSML 음성 합성
     */
    @PostMapping("/tts/synthesize-ssml")
    public ResponseEntity<Map<String, Object>> synthesizeSsml(@RequestBody Map<String, Object> request) {
        String ssml = (String) request.get("ssml");
        String voiceName = (String) request.get("voiceName");
        String languageCode = (String) request.get("languageCode");

        Map<String, Object> result = textToSpeechService.synthesizeSsml(ssml, voiceName, languageCode);
        return ResponseEntity.ok(result);
    }

    /**
     * 사용 가능한 음성 목록
     */
    @GetMapping("/tts/voices")
    public ResponseEntity<Map<String, Object>> listVoices(
            @RequestParam(required = false) String languageCode) {
        List<Map<String, Object>> voices = textToSpeechService.listVoices(languageCode);
        return ResponseEntity.ok(Map.of("success", true, "voices", voices));
    }

    // ==================== Speech-to-Text API ====================

    /**
     * 음성을 텍스트로 변환
     */
    @PostMapping("/stt/recognize")
    public ResponseEntity<Map<String, Object>> recognizeSpeech(
            @RequestParam("audio") MultipartFile audio,
            @RequestParam(required = false) String languageCode) throws IOException {

        Map<String, Object> result = speechToTextService.recognizeSpeech(audio.getBytes(), languageCode, 0);
        return ResponseEntity.ok(result);
    }

    /**
     * Base64 오디오 음성 인식
     */
    @PostMapping("/stt/recognize-base64")
    public ResponseEntity<Map<String, Object>> recognizeSpeechBase64(@RequestBody Map<String, Object> request) {
        String audioBase64 = (String) request.get("audio");
        String languageCode = (String) request.get("languageCode");
        int sampleRate = ((Number) request.getOrDefault("sampleRate", 16000)).intValue();

        byte[] audioData = java.util.Base64.getDecoder().decode(audioBase64);
        Map<String, Object> result = speechToTextService.recognizeSpeech(audioData, languageCode, sampleRate);
        return ResponseEntity.ok(result);
    }

    /**
     * 장시간 음성 인식 시작
     */
    @PostMapping("/stt/long-running")
    public ResponseEntity<Map<String, Object>> recognizeLongAudio(@RequestBody Map<String, String> request) {
        String gcsUri = request.get("gcsUri");
        String languageCode = request.get("languageCode");

        Map<String, Object> result = speechToTextService.recognizeLongAudio(gcsUri, languageCode);
        return ResponseEntity.ok(result);
    }

    /**
     * 장시간 음성 인식 결과 조회
     */
    @GetMapping("/stt/long-running/{operationName}")
    public ResponseEntity<Map<String, Object>> getLongAudioResult(@PathVariable String operationName) {
        Map<String, Object> result = speechToTextService.getLongAudioResult(operationName);
        return ResponseEntity.ok(result);
    }

    /**
     * 스트리밍 설정 정보
     */
    @GetMapping("/stt/streaming-config")
    public ResponseEntity<Map<String, Object>> getStreamingConfig() {
        Map<String, Object> config = speechToTextService.getStreamingConfig();
        return ResponseEntity.ok(Map.of("success", true, "config", config));
    }

    // ==================== 헬스체크 ====================

    /**
     * 전체 GCP 서비스 상태
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        return ResponseEntity.ok(Map.of(
            "status", "UP",
            "services", Map.of(
                "vertexAi", vertexAiService.healthCheck(),
                "bigQuery", bigQueryService.healthCheck(),
                "textToSpeech", textToSpeechService.healthCheck(),
                "speechToText", speechToTextService.healthCheck()
            ),
            "timestamp", java.time.LocalDateTime.now().toString()
        ));
    }
}
