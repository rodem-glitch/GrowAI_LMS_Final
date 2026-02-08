// ai/repository/AiChatHistoryRepository.java — AI 대화 이력 레포지토리
package kr.polytech.epoly.ai.repository;

import kr.polytech.epoly.ai.entity.AiChatHistory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AiChatHistoryRepository extends JpaRepository<AiChatHistory, Long> {

    List<AiChatHistory> findByUserIdAndSessionIdOrderByCreatedAtAsc(Long userId, String sessionId);

    List<AiChatHistory> findTop20ByUserIdOrderByCreatedAtDesc(Long userId);
}
