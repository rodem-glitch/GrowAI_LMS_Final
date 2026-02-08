// ai/repository/AiRecommendationRepository.java — AI 추천 레포지토리
package kr.polytech.epoly.ai.repository;

import kr.polytech.epoly.ai.entity.AiRecommendation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AiRecommendationRepository extends JpaRepository<AiRecommendation, Long> {

    List<AiRecommendation> findByUserIdOrderByScoreDesc(Long userId);

    List<AiRecommendation> findByUserIdAndRecommendType(Long userId, String recommendType);
}
