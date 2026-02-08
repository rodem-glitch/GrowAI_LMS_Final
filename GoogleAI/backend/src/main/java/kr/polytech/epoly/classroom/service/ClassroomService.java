// classroom/service/ClassroomService.java — 학습실 서비스
package kr.polytech.epoly.classroom.service;

import kr.polytech.epoly.classroom.entity.*;
import kr.polytech.epoly.classroom.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ClassroomService {

    private final LessonRepository lessonRepository;
    private final AttendanceRepository attendanceRepository;
    private final AssignmentRepository assignmentRepository;
    private final AssignmentSubmissionRepository submissionRepository;
    private final ExamRepository examRepository;

    /** 강좌 차시 목록 (주차별 정렬) */
    public List<Lesson> getLessons(Long courseId) {
        return lessonRepository.findByCourseIdOrderByWeekNoAscOrderNoAsc(courseId);
    }

    /** 특정 주차 차시 목록 */
    public List<Lesson> getLessonsByWeek(Long courseId, Integer weekNo) {
        return lessonRepository.findByCourseIdAndWeekNo(courseId, weekNo);
    }

    /** 학습 진도 기록/갱신 */
    @Transactional
    public Attendance updateProgress(Long userId, Long lessonId, Long courseId, int watchedSeconds, int totalSeconds) {
        Attendance att = attendanceRepository.findByUserIdAndLessonId(userId, lessonId)
                .orElse(Attendance.builder()
                        .userId(userId).lessonId(lessonId).courseId(courseId)
                        .status("PRESENT").startedAt(LocalDateTime.now())
                        .build());

        att.setWatchedSeconds(watchedSeconds);
        att.setTotalSeconds(totalSeconds);
        int progress = totalSeconds > 0 ? (int) ((watchedSeconds * 100L) / totalSeconds) : 0;
        att.setProgressPercent(progress);

        if (progress >= 90 && !att.getCompleted()) {
            att.setCompleted(true);
            att.setCompletedAt(LocalDateTime.now());
            att.setStatus("PRESENT");
        }

        return attendanceRepository.save(att);
    }

    /** 사용자의 강좌 출석 현황 */
    public List<Attendance> getMyAttendance(Long userId, Long courseId) {
        return attendanceRepository.findByUserIdAndCourseId(userId, courseId);
    }

    /** 완료 차시 수 */
    public long getCompletedLessonCount(Long userId, Long courseId) {
        return attendanceRepository.countCompletedLessons(userId, courseId);
    }

    /** 총 차시 수 */
    public long getTotalLessonCount(Long courseId) {
        return lessonRepository.countByCourseId(courseId);
    }

    /** 과제 목록 */
    public List<Assignment> getAssignments(Long courseId) {
        return assignmentRepository.findByCourseId(courseId);
    }

    /** 과제 제출 */
    @Transactional
    public AssignmentSubmission submitAssignment(Long assignmentId, Long userId, String content, String fileUrl) {
        submissionRepository.findByAssignmentIdAndUserId(assignmentId, userId)
                .ifPresent(s -> { throw new IllegalArgumentException("이미 제출된 과제입니다."); });

        AssignmentSubmission submission = AssignmentSubmission.builder()
                .assignmentId(assignmentId).userId(userId)
                .content(content).fileUrl(fileUrl)
                .status("SUBMITTED")
                .build();
        return submissionRepository.save(submission);
    }

    /** 시험 목록 */
    public List<Exam> getExams(Long courseId) {
        return examRepository.findByCourseId(courseId);
    }
}
