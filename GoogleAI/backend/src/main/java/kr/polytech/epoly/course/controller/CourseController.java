// course/controller/CourseController.java — 강좌 API
package kr.polytech.epoly.course.controller;

import kr.polytech.epoly.common.ApiResponse;
import kr.polytech.epoly.course.entity.Course;
import kr.polytech.epoly.course.entity.Enrollment;
import kr.polytech.epoly.course.service.CourseService;
import kr.polytech.epoly.user.entity.User;
import kr.polytech.epoly.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/courses")
@RequiredArgsConstructor
public class CourseController {

    private final CourseService courseService;
    private final UserService userService;

    /** 강좌 목록 */
    @GetMapping
    public ResponseEntity<ApiResponse<List<Course>>> list(
            @RequestParam(required = false) String keyword) {
        List<Course> courses = (keyword != null && !keyword.isBlank())
                ? courseService.searchCourses(keyword)
                : courseService.findAll();
        return ResponseEntity.ok(ApiResponse.ok(courses, courses.size()));
    }

    /** 강좌 상세 */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Course>> detail(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(courseService.findById(id)));
    }

    /** 인기 강좌 */
    @GetMapping("/top")
    public ResponseEntity<ApiResponse<List<Course>>> topCourses() {
        return ResponseEntity.ok(ApiResponse.ok(courseService.findTopCourses()));
    }

    /** 수강 등록 */
    @PostMapping("/{courseId}/enroll")
    public ResponseEntity<ApiResponse<Enrollment>> enroll(
            @PathVariable Long courseId, Authentication auth) {
        User user = userService.findByUserId(auth.getName());
        Enrollment enrollment = courseService.enroll(user.getId(), courseId);
        return ResponseEntity.ok(ApiResponse.ok(enrollment));
    }

    /** 내 수강 목록 */
    @GetMapping("/my")
    public ResponseEntity<ApiResponse<List<Enrollment>>> myEnrollments(
            Authentication auth,
            @RequestParam(required = false) String status) {
        User user = userService.findByUserId(auth.getName());
        List<Enrollment> list = (status != null)
                ? courseService.getEnrollmentsByStatus(user.getId(), status)
                : courseService.getMyEnrollments(user.getId());
        return ResponseEntity.ok(ApiResponse.ok(list, list.size()));
    }
}
