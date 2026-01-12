package kr.polytech.lms.recocontent.repository;

import java.util.Optional;
import kr.polytech.lms.recocontent.entity.RecoContent;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RecoContentRepository extends JpaRepository<RecoContent, Long> {
    boolean existsByLessonId(String lessonId);

    Optional<RecoContent> findTopByLessonIdOrderByIdDesc(String lessonId);
}

