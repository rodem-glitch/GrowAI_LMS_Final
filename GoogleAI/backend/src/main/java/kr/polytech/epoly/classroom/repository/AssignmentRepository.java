// classroom/repository/AssignmentRepository.java — 과제 레포지토리
package kr.polytech.epoly.classroom.repository;

import kr.polytech.epoly.classroom.entity.Assignment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AssignmentRepository extends JpaRepository<Assignment, Long> {
    List<Assignment> findByCourseId(Long courseId);
}
