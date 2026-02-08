// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/controller/CourseController.java
package kr.polytech.lms.legacy.controller;

import kr.polytech.lms.legacy.dto.CourseDto;
import kr.polytech.lms.legacy.service.CourseService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 과정 REST API Controller
 * 레거시 JSP 컨트롤러를 REST API로 변환
 */
@Slf4j
@RestController
@RequestMapping("/api/courses")
@RequiredArgsConstructor
public class CourseController {

    private final CourseService courseService;

    /**
     * 사이트별 과정 목록 조회
     */
    @GetMapping
    public ResponseEntity<List<CourseDto>> getCourseList(
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId) {
        log.debug("과정 목록 조회 - siteId: {}", siteId);
        List<CourseDto> courses = courseService.getCourseList(siteId);
        return ResponseEntity.ok(courses);
    }

    /**
     * 과정 상세 조회
     */
    @GetMapping("/{id}")
    public ResponseEntity<CourseDto> getCourse(
            @PathVariable Long id,
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId) {
        log.debug("과정 상세 조회 - id: {}, siteId: {}", id, siteId);
        return courseService.getCourse(id, siteId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * 판매 중인 과정 조회
     */
    @GetMapping("/sale")
    public ResponseEntity<List<CourseDto>> getActiveSaleCourses(
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId) {
        List<CourseDto> courses = courseService.getActiveSaleCourses(siteId);
        return ResponseEntity.ok(courses);
    }

    /**
     * 패키지 과정 조회
     */
    @GetMapping("/packages")
    public ResponseEntity<List<CourseDto>> getPackageCourses(
            @RequestHeader(value = "X-Site-Id", defaultValue = "1") Long siteId) {
        List<CourseDto> courses = courseService.getPackageCourses(siteId);
        return ResponseEntity.ok(courses);
    }

    /**
     * 과정 복사
     */
    @PostMapping("/{id}/copy")
    public ResponseEntity<Long> copyCourse(
            @PathVariable Long id,
            @RequestParam Integer year,
            @RequestParam Integer step,
            @RequestParam String courseNm,
            @RequestParam(required = false) String requestSdate,
            @RequestParam(required = false) String requestEdate,
            @RequestParam(required = false) String studySdate,
            @RequestParam(required = false) String studyEdate,
            @RequestParam(required = false) Integer lessonDay) {
        log.info("과정 복사 요청 - 원본: {}, 연도: {}, 차수: {}", id, year, step);
        Long newId = courseService.copyCourse(id, year, step, courseNm,
                requestSdate, requestEdate, studySdate, studyEdate, lessonDay);
        if (newId < 0) {
            return ResponseEntity.badRequest().body(newId);
        }
        return ResponseEntity.ok(newId);
    }
}
