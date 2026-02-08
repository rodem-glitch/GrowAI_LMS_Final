// classroom/repository/AssignmentSubmissionRepository.java — 과제제출 레포지토리
package kr.polytech.epoly.classroom.repository;

import kr.polytech.epoly.classroom.entity.AssignmentSubmission;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AssignmentSubmissionRepository extends JpaRepository<AssignmentSubmission, Long> {

    Optional<AssignmentSubmission> findByAssignmentIdAndUserId(Long assignmentId, Long userId);

    List<AssignmentSubmission> findByAssignmentId(Long assignmentId);

    List<AssignmentSubmission> findByUserId(Long userId);
}
