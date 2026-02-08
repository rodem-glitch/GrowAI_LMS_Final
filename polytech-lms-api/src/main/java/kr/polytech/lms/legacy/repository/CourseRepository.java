// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/repository/CourseRepository.java
package kr.polytech.lms.legacy.repository;

import kr.polytech.lms.legacy.entity.Course;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 과정 Repository
 * 레거시 CourseDao를 Spring Data JPA로 변환
 */
@Repository
public interface CourseRepository extends JpaRepository<Course, Long> {

    /**
     * 사이트별 활성 과정 목록 조회
     */
    @Query("SELECT c FROM Course c WHERE c.siteId = :siteId AND c.status != -1 ORDER BY c.courseNm ASC, c.regDate DESC")
    List<Course> findBySiteId(@Param("siteId") Long siteId);

    /**
     * 사이트별 과정 상세 조회
     */
    @Query("SELECT c FROM Course c WHERE c.id = :id AND c.siteId = :siteId AND c.status != -1")
    Optional<Course> findByIdAndSiteId(@Param("id") Long id, @Param("siteId") Long siteId);

    /**
     * 패키지 과정 제외 조회
     */
    @Query("SELECT c FROM Course c WHERE c.siteId = :siteId AND c.status != -1 AND c.onoffType != 'P' ORDER BY c.courseNm ASC")
    List<Course> findNonPackageCourses(@Param("siteId") Long siteId);

    /**
     * 패키지 과정만 조회
     */
    @Query("SELECT c FROM Course c WHERE c.siteId = :siteId AND c.status != -1 AND c.onoffType = 'P' ORDER BY c.courseNm ASC")
    List<Course> findPackageCourses(@Param("siteId") Long siteId);

    /**
     * 판매 중인 과정 조회
     */
    @Query("SELECT c FROM Course c WHERE c.siteId = :siteId AND c.status = 1 AND c.displayYn = 'Y' AND c.saleYn = 'Y' ORDER BY c.sort ASC")
    List<Course> findActiveSaleCourses(@Param("siteId") Long siteId);

    /**
     * 연도/차수별 과정 조회
     */
    @Query("SELECT c FROM Course c WHERE c.siteId = :siteId AND c.year = :year AND c.step = :step AND c.status != -1")
    List<Course> findByYearAndStep(@Param("siteId") Long siteId, @Param("year") Integer year, @Param("step") Integer step);
}
