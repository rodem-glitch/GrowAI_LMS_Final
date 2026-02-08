// course/repository/CourseRepository.java — 강좌 레포지토리
package kr.polytech.epoly.course.repository;

import kr.polytech.epoly.course.entity.Course;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface CourseRepository extends JpaRepository<Course, Long> {

    Optional<Course> findByCourseCode(String courseCode);

    List<Course> findByInstructorId(Long instructorId);

    List<Course> findByCampus(String campus);

    List<Course> findByCategory(String category);

    List<Course> findByStatus(String status);

    @Query("SELECT c FROM Course c WHERE c.title LIKE %:keyword% OR c.courseCode LIKE %:keyword%")
    List<Course> searchByKeyword(@Param("keyword") String keyword);

    @Query("SELECT c FROM Course c WHERE c.status = 'ACTIVE' ORDER BY c.enrolledCount DESC")
    List<Course> findTopCourses();
}
