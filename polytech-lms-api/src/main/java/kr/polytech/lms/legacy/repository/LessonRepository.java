// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/repository/LessonRepository.java
package kr.polytech.lms.legacy.repository;

import kr.polytech.lms.legacy.entity.Lesson;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 차시 Repository
 * 레거시 LessonDao를 Spring Data JPA로 변환
 */
@Repository
public interface LessonRepository extends JpaRepository<Lesson, Long> {

    /**
     * 과정별 차시 목록 조회
     */
    @Query("SELECT l FROM Lesson l WHERE l.courseId = :courseId AND l.status != -1 ORDER BY l.sort ASC, l.lessonNo ASC")
    List<Lesson> findByCourseId(@Param("courseId") Long courseId);

    /**
     * 과정 및 사이트별 차시 조회
     */
    @Query("SELECT l FROM Lesson l WHERE l.courseId = :courseId AND l.siteId = :siteId AND l.status != -1 ORDER BY l.sort ASC")
    List<Lesson> findByCourseIdAndSiteId(@Param("courseId") Long courseId, @Param("siteId") Long siteId);

    /**
     * 차시 상세 조회
     */
    @Query("SELECT l FROM Lesson l WHERE l.id = :id AND l.siteId = :siteId AND l.status != -1")
    Optional<Lesson> findByIdAndSiteId(@Param("id") Long id, @Param("siteId") Long siteId);

    /**
     * 영상 키로 차시 조회
     */
    @Query("SELECT l FROM Lesson l WHERE l.videoKey = :videoKey AND l.status != -1")
    List<Lesson> findByVideoKey(@Param("videoKey") String videoKey);

    /**
     * 과정별 총 재생시간 조회
     */
    @Query("SELECT COALESCE(SUM(l.playTime), 0) FROM Lesson l WHERE l.courseId = :courseId AND l.status != -1")
    Integer getTotalPlayTime(@Param("courseId") Long courseId);

    /**
     * 과정별 차시 수 조회
     */
    @Query("SELECT COUNT(l) FROM Lesson l WHERE l.courseId = :courseId AND l.status != -1")
    Long countByCourseId(@Param("courseId") Long courseId);
}
