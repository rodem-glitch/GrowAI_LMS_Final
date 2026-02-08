// classroom/repository/ExamRepository.java — 시험 레포지토리
package kr.polytech.epoly.classroom.repository;

import kr.polytech.epoly.classroom.entity.Exam;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ExamRepository extends JpaRepository<Exam, Long> {
    List<Exam> findByCourseId(Long courseId);
}
