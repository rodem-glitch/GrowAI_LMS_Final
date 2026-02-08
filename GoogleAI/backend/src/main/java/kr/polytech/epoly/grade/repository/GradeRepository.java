// grade/repository/GradeRepository.java — 성적 레포지토리
package kr.polytech.epoly.grade.repository;

import kr.polytech.epoly.grade.entity.Grade;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface GradeRepository extends JpaRepository<Grade, Long> {

    Optional<Grade> findByUserIdAndCourseId(Long userId, Long courseId);

    List<Grade> findByUserId(Long userId);

    List<Grade> findByCourseId(Long courseId);

    @Query("SELECT AVG(g.totalScore) FROM Grade g WHERE g.courseId = :courseId")
    Double getAverageScore(@Param("courseId") Long courseId);

    @Query("SELECT COUNT(g) FROM Grade g WHERE g.courseId = :courseId AND g.passed = true")
    long countPassedByCourse(@Param("courseId") Long courseId);
}
