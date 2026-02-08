// classroom/repository/LessonRepository.java — 차시 레포지토리
package kr.polytech.epoly.classroom.repository;

import kr.polytech.epoly.classroom.entity.Lesson;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LessonRepository extends JpaRepository<Lesson, Long> {

    List<Lesson> findByCourseIdOrderByWeekNoAscOrderNoAsc(Long courseId);

    List<Lesson> findByCourseIdAndWeekNo(Long courseId, Integer weekNo);

    long countByCourseId(Long courseId);
}
