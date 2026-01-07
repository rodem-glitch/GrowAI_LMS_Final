package kr.polytech.lms.recocontent.repository;

import java.util.Optional;
import kr.polytech.lms.recocontent.entity.RecoContent;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RecoContentRepository extends JpaRepository<RecoContent, Long> {
    Optional<RecoContent> findByLessonId(String lessonId);
}

