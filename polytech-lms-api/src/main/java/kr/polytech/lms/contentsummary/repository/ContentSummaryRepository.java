package kr.polytech.lms.contentsummary.repository;

import java.util.Optional;
import kr.polytech.lms.contentsummary.entity.KollusTranscript;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ContentSummaryRepository extends JpaRepository<KollusTranscript, Long> {
    Optional<KollusTranscript> findBySiteIdAndMediaContentKey(Integer siteId, String mediaContentKey);
    
    java.util.List<KollusTranscript> findByDurationSecondsIsNull();
}
