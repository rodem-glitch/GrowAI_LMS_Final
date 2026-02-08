// classroom/controller/ClassroomController.java — 학습실 API
package kr.polytech.epoly.classroom.controller;

import kr.polytech.epoly.classroom.entity.*;
import kr.polytech.epoly.classroom.service.ClassroomService;
import kr.polytech.epoly.common.ApiResponse;
import kr.polytech.epoly.user.entity.User;
import kr.polytech.epoly.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/classroom")
@RequiredArgsConstructor
public class ClassroomController {

    private final ClassroomService classroomService;
    private final UserService userService;

    /** 강좌 차시 목록 */
    @GetMapping("/courses/{courseId}/lessons")
    public ResponseEntity<ApiResponse<List<Lesson>>> lessons(@PathVariable Long courseId) {
        List<Lesson> lessons = classroomService.getLessons(courseId);
        return ResponseEntity.ok(ApiResponse.ok(lessons, lessons.size()));
    }

    /** 학습 진도 업데이트 */
    @PostMapping("/lessons/{lessonId}/progress")
    public ResponseEntity<ApiResponse<Attendance>> updateProgress(
            @PathVariable Long lessonId,
            @RequestParam Long courseId,
            @RequestParam int watchedSeconds,
            @RequestParam int totalSeconds,
            Authentication auth) {
        User user = userService.findByUserId(auth.getName());
        Attendance att = classroomService.updateProgress(user.getId(), lessonId, courseId, watchedSeconds, totalSeconds);
        return ResponseEntity.ok(ApiResponse.ok(att));
    }

    /** 내 출석 현황 */
    @GetMapping("/courses/{courseId}/attendance")
    public ResponseEntity<ApiResponse<Map<String, Object>>> myAttendance(
            @PathVariable Long courseId, Authentication auth) {
        User user = userService.findByUserId(auth.getName());
        List<Attendance> attendances = classroomService.getMyAttendance(user.getId(), courseId);
        long completed = classroomService.getCompletedLessonCount(user.getId(), courseId);
        long total = classroomService.getTotalLessonCount(courseId);

        Map<String, Object> result = new HashMap<>();
        result.put("attendances", attendances);
        result.put("completedCount", completed);
        result.put("totalCount", total);
        result.put("progressPercent", total > 0 ? (int) (completed * 100 / total) : 0);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    /** 과제 목록 */
    @GetMapping("/courses/{courseId}/assignments")
    public ResponseEntity<ApiResponse<List<Assignment>>> assignments(@PathVariable Long courseId) {
        return ResponseEntity.ok(ApiResponse.ok(classroomService.getAssignments(courseId)));
    }

    /** 과제 제출 */
    @PostMapping("/assignments/{assignmentId}/submit")
    public ResponseEntity<ApiResponse<AssignmentSubmission>> submitAssignment(
            @PathVariable Long assignmentId,
            @RequestParam(required = false) String content,
            @RequestParam(required = false) String fileUrl,
            Authentication auth) {
        User user = userService.findByUserId(auth.getName());
        AssignmentSubmission sub = classroomService.submitAssignment(assignmentId, user.getId(), content, fileUrl);
        return ResponseEntity.ok(ApiResponse.ok(sub));
    }

    /** 시험 목록 */
    @GetMapping("/courses/{courseId}/exams")
    public ResponseEntity<ApiResponse<List<Exam>>> exams(@PathVariable Long courseId) {
        return ResponseEntity.ok(ApiResponse.ok(classroomService.getExams(courseId)));
    }
}
