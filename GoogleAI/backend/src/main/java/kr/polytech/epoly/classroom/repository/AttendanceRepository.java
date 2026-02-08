// classroom/repository/AttendanceRepository.java — 출석 레포지토리
package kr.polytech.epoly.classroom.repository;

import kr.polytech.epoly.classroom.entity.Attendance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface AttendanceRepository extends JpaRepository<Attendance, Long> {

    Optional<Attendance> findByUserIdAndLessonId(Long userId, Long lessonId);

    List<Attendance> findByUserIdAndCourseId(Long userId, Long courseId);

    @Query("SELECT COUNT(a) FROM Attendance a WHERE a.userId = :userId AND a.courseId = :courseId AND a.completed = true")
    long countCompletedLessons(@Param("userId") Long userId, @Param("courseId") Long courseId);

    @Query("SELECT AVG(a.progressPercent) FROM Attendance a WHERE a.userId = :userId AND a.courseId = :courseId")
    Double getAverageProgress(@Param("userId") Long userId, @Param("courseId") Long courseId);
}
