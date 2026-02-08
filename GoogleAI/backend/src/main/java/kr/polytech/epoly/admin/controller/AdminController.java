// admin/controller/AdminController.java — 관리자 API
package kr.polytech.epoly.admin.controller;

import kr.polytech.epoly.common.ApiResponse;
import kr.polytech.epoly.course.entity.Course;
import kr.polytech.epoly.course.service.CourseService;
import kr.polytech.epoly.user.entity.User;
import kr.polytech.epoly.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminController {

    private final UserService userService;
    private final CourseService courseService;

    /** 대시보드 통계 */
    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<Map<String, Object>>> dashboard() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalStudents", userService.countActiveByType("STUDENT"));
        stats.put("totalInstructors", userService.countActiveByType("INSTRUCTOR"));
        stats.put("totalCourses", courseService.findAll().size());
        stats.put("topCourses", courseService.findTopCourses());
        return ResponseEntity.ok(ApiResponse.ok(stats));
    }

    /** 사용자 목록 */
    @GetMapping("/users")
    public ResponseEntity<ApiResponse<List<User>>> users(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String keyword) {
        List<User> users;
        if (keyword != null && !keyword.isBlank()) {
            users = userService.searchUsers(keyword);
        } else if (type != null && !type.isBlank()) {
            users = userService.findByUserType(type);
        } else {
            users = userService.findByUserType("STUDENT");
        }
        return ResponseEntity.ok(ApiResponse.ok(users, users.size()));
    }

    /** 사용자 생성 */
    @PostMapping("/users")
    public ResponseEntity<ApiResponse<User>> createUser(@RequestBody User user) {
        return ResponseEntity.ok(ApiResponse.ok(userService.createUser(user)));
    }

    /** 사용자 비활성화 */
    @DeleteMapping("/users/{id}")
    public ResponseEntity<ApiResponse<Void>> deactivateUser(@PathVariable Long id) {
        userService.deactivateUser(id);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    /** 강좌 관리 - 생성 */
    @PostMapping("/courses")
    public ResponseEntity<ApiResponse<Course>> createCourse(@RequestBody Course course) {
        return ResponseEntity.ok(ApiResponse.ok(courseService.createCourse(course)));
    }

    /** 강좌 관리 - 수정 */
    @PutMapping("/courses/{id}")
    public ResponseEntity<ApiResponse<Course>> updateCourse(@PathVariable Long id, @RequestBody Course course) {
        return ResponseEntity.ok(ApiResponse.ok(courseService.updateCourse(id, course)));
    }
}
