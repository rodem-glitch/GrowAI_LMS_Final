// course/service/CourseService.java — 강좌 서비스
package kr.polytech.epoly.course.service;

import kr.polytech.epoly.course.entity.Course;
import kr.polytech.epoly.course.entity.Enrollment;
import kr.polytech.epoly.course.repository.CourseRepository;
import kr.polytech.epoly.course.repository.EnrollmentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CourseService {

    private final CourseRepository courseRepository;
    private final EnrollmentRepository enrollmentRepository;

    public Course findById(Long id) {
        return courseRepository.findById(id)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("강좌를 찾을 수 없습니다: " + id));
    }

    public List<Course> findAll() {
        return courseRepository.findAll();
    }

    public List<Course> findByInstructor(Long instructorId) {
        return courseRepository.findByInstructorId(instructorId);
    }

    public List<Course> searchCourses(String keyword) {
        return courseRepository.searchByKeyword(keyword);
    }

    public List<Course> findTopCourses() {
        return courseRepository.findTopCourses();
    }

    @Transactional
    public Course createCourse(Course course) {
        course.setEnrolledCount(0);
        return courseRepository.save(course);
    }

    @Transactional
    public Course updateCourse(Long id, Course updated) {
        Course course = findById(id);
        course.setTitle(updated.getTitle());
        course.setDescription(updated.getDescription());
        course.setCategory(updated.getCategory());
        course.setStartDate(updated.getStartDate());
        course.setEndDate(updated.getEndDate());
        course.setTotalWeeks(updated.getTotalWeeks());
        course.setMaxStudents(updated.getMaxStudents());
        return courseRepository.save(course);
    }

    /** 수강 등록 */
    @Transactional
    public Enrollment enroll(Long userId, Long courseId) {
        if (enrollmentRepository.existsByUserIdAndCourseId(userId, courseId)) {
            throw new IllegalArgumentException("이미 수강 등록된 강좌입니다.");
        }
        Course course = findById(courseId);
        if (course.getMaxStudents() != null && course.getEnrolledCount() >= course.getMaxStudents()) {
            throw new IllegalArgumentException("수강 인원이 초과되었습니다.");
        }
        course.setEnrolledCount(course.getEnrolledCount() + 1);
        courseRepository.save(course);

        Enrollment enrollment = Enrollment.builder()
                .userId(userId).courseId(courseId)
                .status("ENROLLED").progressPercent(0)
                .build();
        return enrollmentRepository.save(enrollment);
    }

    /** 내 수강 목록 */
    public List<Enrollment> getMyEnrollments(Long userId) {
        return enrollmentRepository.findByUserId(userId);
    }

    /** 수강 상태별 목록 */
    public List<Enrollment> getEnrollmentsByStatus(Long userId, String status) {
        return enrollmentRepository.findByUserIdAndStatus(userId, status);
    }
}
