// grade/service/GradeService.java — 성적 서비스
package kr.polytech.epoly.grade.service;

import kr.polytech.epoly.grade.entity.Grade;
import kr.polytech.epoly.grade.repository.GradeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class GradeService {

    private final GradeRepository gradeRepository;

    public Grade findByUserAndCourse(Long userId, Long courseId) {
        return gradeRepository.findByUserIdAndCourseId(userId, courseId)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("성적 정보를 찾을 수 없습니다."));
    }

    public List<Grade> findByUser(Long userId) {
        return gradeRepository.findByUserId(userId);
    }

    public List<Grade> findByCourse(Long courseId) {
        return gradeRepository.findByCourseId(courseId);
    }

    @Transactional
    public Grade saveGrade(Grade grade) {
        // 총점 계산
        grade.setTotalScore(
            grade.getAttendanceScore()
                .add(grade.getAssignmentScore())
                .add(grade.getExamScore())
        );
        // 등급 산정
        double total = grade.getTotalScore().doubleValue();
        if (total >= 95) grade.setLetterGrade("A+");
        else if (total >= 90) grade.setLetterGrade("A");
        else if (total >= 85) grade.setLetterGrade("B+");
        else if (total >= 80) grade.setLetterGrade("B");
        else if (total >= 75) grade.setLetterGrade("C+");
        else if (total >= 70) grade.setLetterGrade("C");
        else if (total >= 60) grade.setLetterGrade("D");
        else grade.setLetterGrade("F");

        grade.setPassed(total >= 60);
        return gradeRepository.save(grade);
    }

    public Double getAverageScore(Long courseId) {
        return gradeRepository.getAverageScore(courseId);
    }
}
