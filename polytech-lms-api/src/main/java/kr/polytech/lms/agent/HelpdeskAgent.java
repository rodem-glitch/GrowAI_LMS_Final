// polytech-lms-api/src/main/java/kr/polytech/lms/agent/HelpdeskAgent.java
package kr.polytech.lms.agent;

import kr.polytech.lms.gcp.service.DialogflowService;
import kr.polytech.lms.gcp.service.VertexAiService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;

/**
 * Helpdesk Agent
 * 사용자 문의 24/7 자동 응대
 * Tech: Dialogflow CX + Gemini API
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class HelpdeskAgent {

    private final DialogflowService dialogflowService;
    private final VertexAiService vertexAiService;

    // 대화 세션 관리
    private final Map<String, ConversationSession> sessions = new ConcurrentHashMap<>();

    // 미해결 티켓 큐
    private final Queue<SupportTicket> pendingTickets = new ConcurrentLinkedQueue<>();

    // FAQ 캐시
    private final Map<String, String> faqCache = new ConcurrentHashMap<>();

    // 통계
    private int totalQueries = 0;
    private int autoResolved = 0;
    private int escalated = 0;

    /**
     * 정기 세션 정리 (30분마다)
     */
    @Scheduled(fixedRate = 1800000)
    public void cleanupSessions() {
        log.debug("Helpdesk Agent: 세션 정리 실행");
        long timeout = System.currentTimeMillis() - 3600000; // 1시간 타임아웃

        sessions.entrySet().removeIf(entry ->
            entry.getValue().lastActivity < timeout
        );
    }

    /**
     * 정기 티켓 처리 (5분마다)
     */
    @Scheduled(fixedRate = 300000)
    public void processPendingTickets() {
        log.debug("Helpdesk Agent: 대기 티켓 처리");

        while (!pendingTickets.isEmpty()) {
            SupportTicket ticket = pendingTickets.poll();
            if (ticket != null && !ticket.resolved) {
                // 자동 응답 재시도
                retryAutoResponse(ticket);
            }
        }
    }

    /**
     * 사용자 문의 처리
     */
    public Map<String, Object> handleQuery(String userId, String query, String sessionId) {
        log.info("Helpdesk Agent: 문의 접수 - user={}, query={}", userId,
            query.length() > 50 ? query.substring(0, 50) + "..." : query);

        totalQueries++;

        // 세션 가져오기 또는 생성
        ConversationSession session = sessions.computeIfAbsent(
            sessionId,
            k -> new ConversationSession(userId, sessionId)
        );
        session.lastActivity = System.currentTimeMillis();
        session.messages.add(new ChatMessage("user", query));

        try {
            // 1. FAQ 캐시 확인
            String cachedAnswer = checkFaqCache(query);
            if (cachedAnswer != null) {
                autoResolved++;
                session.messages.add(new ChatMessage("agent", cachedAnswer));
                return createResponse(cachedAnswer, "FAQ_CACHE", true);
            }

            // 2. Dialogflow로 의도 파악
            Map<String, Object> dialogflowResult = dialogflowService.detectIntent(sessionId, query, "ko");
            String intent = (String) dialogflowResult.get("intent");
            double confidence = (double) dialogflowResult.get("confidence");

            // 3. 높은 신뢰도의 의도는 Dialogflow 응답 사용
            if (confidence > 0.8 && dialogflowResult.get("fulfillmentText") != null) {
                String answer = (String) dialogflowResult.get("fulfillmentText");
                autoResolved++;
                session.messages.add(new ChatMessage("agent", answer));
                cacheFaq(query, answer);
                return createResponse(answer, "DIALOGFLOW", true);
            }

            // 4. Gemini API로 고급 응답 생성
            Map<String, Object> geminiResult = generateGeminiResponse(query, session);
            String answer = (String) geminiResult.get("answer");
            boolean resolved = (boolean) geminiResult.get("resolved");

            if (resolved) {
                autoResolved++;
                session.messages.add(new ChatMessage("agent", answer));
                cacheFaq(query, answer);
                return createResponse(answer, "GEMINI_AI", true);
            }

            // 5. 해결 불가 시 티켓 생성 및 에스컬레이션
            escalated++;
            SupportTicket ticket = new SupportTicket(userId, query, session);
            pendingTickets.add(ticket);

            String escalationMessage = "죄송합니다. 해당 문의는 담당자 확인이 필요합니다. " +
                "티켓 번호: " + ticket.ticketId + " (영업시간 내 답변 드리겠습니다)";
            session.messages.add(new ChatMessage("agent", escalationMessage));

            return createResponse(escalationMessage, "ESCALATED", false);

        } catch (Exception e) {
            log.error("Helpdesk Agent: 문의 처리 오류 - {}", e.getMessage());
            String errorMessage = "일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.";
            return createResponse(errorMessage, "ERROR", false);
        }
    }

    /**
     * FAQ 캐시 확인
     */
    private String checkFaqCache(String query) {
        String normalizedQuery = normalizeQuery(query);
        return faqCache.get(normalizedQuery);
    }

    /**
     * FAQ 캐싱
     */
    private void cacheFaq(String query, String answer) {
        String normalizedQuery = normalizeQuery(query);
        faqCache.put(normalizedQuery, answer);
    }

    /**
     * 쿼리 정규화
     */
    private String normalizeQuery(String query) {
        return query.toLowerCase()
            .replaceAll("[^가-힣a-z0-9\\s]", "")
            .trim();
    }

    /**
     * Gemini API로 응답 생성
     */
    private Map<String, Object> generateGeminiResponse(String query, ConversationSession session) {
        // 대화 컨텍스트 구성
        StringBuilder context = new StringBuilder();
        context.append("LMS 헬프데스크 AI입니다. 다음 문의에 친절하게 답변해주세요.\n\n");

        // 이전 대화 추가
        for (ChatMessage msg : session.messages) {
            context.append(msg.role.equals("user") ? "사용자: " : "상담원: ");
            context.append(msg.content).append("\n");
        }

        // RAG 검색으로 관련 정보 추가
        List<String> contextDocs = List.of(
            "수강신청: 매 학기 개강 2주 전 시작, 마이페이지에서 가능",
            "성적확인: 학기말 성적 공개 후 마이페이지에서 확인",
            "출결관리: 강의실 입장 시 자동 체크, 모바일 앱도 지원",
            "수료증: 과정 완료 후 마이페이지에서 발급 가능"
        );

        Map<String, Object> ragResult = vertexAiService.ragQuery(query, contextDocs);
        String answer = (String) ragResult.get("answer");

        // 응답 품질 평가
        boolean resolved = evaluateResponseQuality(answer, query);

        return Map.of(
            "answer", answer,
            "resolved", resolved,
            "confidence", ragResult.get("confidence")
        );
    }

    /**
     * 응답 품질 평가
     */
    private boolean evaluateResponseQuality(String answer, String query) {
        // 간단한 휴리스틱 평가
        if (answer == null || answer.length() < 20) {
            return false;
        }
        if (answer.contains("모르겠") || answer.contains("확인이 필요") ||
            answer.contains("담당자")) {
            return false;
        }
        return true;
    }

    /**
     * 자동 응답 재시도
     */
    private void retryAutoResponse(SupportTicket ticket) {
        log.debug("Helpdesk Agent: 티켓 재처리 시도 - {}", ticket.ticketId);
        // 재시도 로직 (담당자 배정 또는 추가 AI 분석)
    }

    /**
     * 응답 생성
     */
    private Map<String, Object> createResponse(String message, String source, boolean resolved) {
        return Map.of(
            "message", message,
            "source", source,
            "resolved", resolved,
            "timestamp", LocalDateTime.now().toString()
        );
    }

    /**
     * 티켓 상태 조회
     */
    public Map<String, Object> getTicketStatus(String ticketId) {
        for (SupportTicket ticket : pendingTickets) {
            if (ticket.ticketId.equals(ticketId)) {
                return Map.of(
                    "ticketId", ticketId,
                    "status", ticket.resolved ? "RESOLVED" : "PENDING",
                    "query", ticket.query,
                    "createdAt", ticket.createdAt.toString()
                );
            }
        }
        return Map.of("ticketId", ticketId, "status", "NOT_FOUND");
    }

    /**
     * 티켓 해결 처리
     */
    public void resolveTicket(String ticketId, String resolution) {
        for (SupportTicket ticket : pendingTickets) {
            if (ticket.ticketId.equals(ticketId)) {
                ticket.resolved = true;
                ticket.resolution = resolution;
                log.info("Helpdesk Agent: 티켓 해결 - {}", ticketId);
                break;
            }
        }
    }

    /**
     * 에이전트 상태 조회
     */
    public Map<String, Object> getStatus() {
        double autoResolveRate = totalQueries > 0 ?
            (double) autoResolved / totalQueries * 100 : 0;

        Map<String, Object> status = new HashMap<>();
        status.put("agent", "HelpdeskAgent");
        status.put("role", "사용자 문의 24/7 자동 응대");
        status.put("tech", "Dialogflow CX + Gemini API");
        status.put("totalQueries", totalQueries);
        status.put("autoResolved", autoResolved);
        status.put("escalated", escalated);
        status.put("autoResolveRate", String.format("%.1f%%", autoResolveRate));
        status.put("activeSessions", sessions.size());
        status.put("pendingTickets", pendingTickets.size());
        status.put("faqCacheSize", faqCache.size());
        status.put("status", "ACTIVE");
        return status;
    }

    /**
     * 대화 세션 내부 클래스
     */
    private static class ConversationSession {
        String userId;
        String sessionId;
        List<ChatMessage> messages = new ArrayList<>();
        long lastActivity;

        ConversationSession(String userId, String sessionId) {
            this.userId = userId;
            this.sessionId = sessionId;
            this.lastActivity = System.currentTimeMillis();
        }
    }

    /**
     * 채팅 메시지 내부 클래스
     */
    private record ChatMessage(String role, String content) {}

    /**
     * 지원 티켓 내부 클래스
     */
    private static class SupportTicket {
        String ticketId;
        String userId;
        String query;
        ConversationSession session;
        LocalDateTime createdAt;
        boolean resolved;
        String resolution;

        SupportTicket(String userId, String query, ConversationSession session) {
            this.ticketId = "TKT-" + System.currentTimeMillis();
            this.userId = userId;
            this.query = query;
            this.session = session;
            this.createdAt = LocalDateTime.now();
            this.resolved = false;
        }
    }
}
