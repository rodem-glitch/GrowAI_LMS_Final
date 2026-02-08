// grade/controller/GradeController.java — 성적 API
package kr.polytech.epoly.grade.controller;

import kr.polytech.epoly.common.ApiResponse;
import kr.polytech.epoly.grade.entity.Grade;
import kr.polytech.epoly.grade.service.GradeService;
import kr.polytech.epoly.user.entity.User;
import kr.polytech.epoly.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/grades")
@RequiredArgsConstructor
public class GradeController {

    private final GradeService gradeService;
    private final UserService userService;

    /** 내 성적 */
    @GetMapping("/my")
    public ResponseEntity<ApiResponse<List<Grade>>> myGrades(Authentication auth) {
        User user = userService.findByUserId(auth.getName());
        return ResponseEntity.ok(ApiResponse.ok(gradeService.findByUser(user.getId())));
    }

    /** 강좌별 내 성적 */
    @GetMapping("/my/{courseId}")
    public ResponseEntity<ApiResponse<Grade>> myCourseGrade(
            @PathVariable Long courseId, Authentication auth) {
        User user = userService.findByUserId(auth.getName());
        return ResponseEntity.ok(ApiResponse.ok(gradeService.findByUserAndCourse(user.getId(), courseId)));
    }

    /** 강좌 성적 목록 (교수자/관리자) */
    @GetMapping("/courses/{courseId}")
    public ResponseEntity<ApiResponse<List<Grade>>> courseGrades(@PathVariable Long courseId) {
        List<Grade> grades = gradeService.findByCourse(courseId);
        return ResponseEntity.ok(ApiResponse.ok(grades, grades.size()));
    }

    /** 성적 등록/수정 */
    @PostMapping
    public ResponseEntity<ApiResponse<Grade>> saveGrade(@RequestBody Grade grade) {
        return ResponseEntity.ok(ApiResponse.ok(gradeService.saveGrade(grade)));
    }
}
