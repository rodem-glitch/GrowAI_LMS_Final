// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/repository/CourseUserRepository.java
package kr.polytech.lms.legacy.repository;

import kr.polytech.lms.legacy.entity.CourseUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 수강생 Repository
 * 레거시 CourseUserDao를 Spring Data JPA로 변환
 */
@Repository
public interface CourseUserRepository extends JpaRepository<CourseUser, Long> {

    /**
     * 사용자의 수강 내역 조회
     */
    @Query("SELECT cu FROM CourseUser cu WHERE cu.userId = :userId AND cu.siteId = :siteId AND cu.status != -1 ORDER BY cu.regDate DESC")
    List<CourseUser> findByUserId(@Param("userId") Long userId, @Param("siteId") Long siteId);

    /**
     * 과정별 수강생 목록 조회
     */
    @Query("SELECT cu FROM CourseUser cu WHERE cu.courseId = :courseId AND cu.siteId = :siteId AND cu.status != -1 ORDER BY cu.regDate DESC")
    List<CourseUser> findByCourseId(@Param("courseId") Long courseId, @Param("siteId") Long siteId);

    /**
     * 특정 사용자의 특정 과정 수강 정보 조회
     */
    @Query("SELECT cu FROM CourseUser cu WHERE cu.userId = :userId AND cu.courseId = :courseId AND cu.status != -1")
    Optional<CourseUser> findByUserIdAndCourseId(@Param("userId") Long userId, @Param("courseId") Long courseId);

    /**
     * 수료자 조회
     */
    @Query("SELECT cu FROM CourseUser cu WHERE cu.courseId = :courseId AND cu.siteId = :siteId AND cu.completeYn = 'Y' AND cu.status != -1")
    List<CourseUser> findCompletedUsers(@Param("courseId") Long courseId, @Param("siteId") Long siteId);

    /**
     * 수강 중인 사용자 수 조회
     */
    @Query("SELECT COUNT(cu) FROM CourseUser cu WHERE cu.courseId = :courseId AND cu.status = 1")
    Long countActiveLearners(@Param("courseId") Long courseId);

    /**
     * 수료율 계산을 위한 통계
     */
    @Query("SELECT COUNT(cu), SUM(CASE WHEN cu.completeYn = 'Y' THEN 1 ELSE 0 END) FROM CourseUser cu WHERE cu.courseId = :courseId AND cu.status != -1")
    Object[] getCompletionStats(@Param("courseId") Long courseId);
}
