// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/repository/UserRepository.java
package kr.polytech.lms.legacy.repository;

import kr.polytech.lms.legacy.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 사용자 Repository
 * 레거시 UserDao를 Spring Data JPA로 변환
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * 로그인 ID로 사용자 조회
     */
    @Query("SELECT u FROM User u WHERE u.loginId = :loginId AND u.siteId = :siteId AND u.status != -1")
    Optional<User> findByLoginIdAndSiteId(@Param("loginId") String loginId, @Param("siteId") Long siteId);

    /**
     * 사이트별 관리자 목록 조회
     */
    @Query("SELECT u FROM User u WHERE u.siteId = :siteId AND u.status = 1 AND u.userKind IN :kinds ORDER BY u.userKind ASC, u.userNm ASC")
    List<User> findManagers(@Param("siteId") Long siteId, @Param("kinds") List<String> kinds);

    /**
     * 사이트별 활성 사용자 조회
     */
    @Query("SELECT u FROM User u WHERE u.siteId = :siteId AND u.status = 1 ORDER BY u.regDate DESC")
    List<User> findActiveUsers(@Param("siteId") Long siteId);

    /**
     * 휴면 대상자 조회
     */
    @Query("SELECT u FROM User u WHERE u.siteId = :siteId AND u.status = 30")
    List<User> findDormantUsers(@Param("siteId") Long siteId);

    /**
     * 이메일로 사용자 조회
     */
    @Query("SELECT u FROM User u WHERE u.email = :email AND u.siteId = :siteId AND u.status != -1")
    Optional<User> findByEmailAndSiteId(@Param("email") String email, @Param("siteId") Long siteId);

    /**
     * 중복정보로 사용자 존재 여부 확인
     */
    @Query("SELECT COUNT(u) > 0 FROM User u WHERE u.dupinfo = :dupinfo AND u.siteId = :siteId AND u.status != -1")
    boolean existsByDupinfoAndSiteId(@Param("dupinfo") String dupinfo, @Param("siteId") Long siteId);

    /**
     * 사용자 탈퇴 처리
     */
    @Modifying
    @Query("UPDATE User u SET u.userNm = '[탈퇴]', u.email = '', u.mobile = '', u.passwd = '', u.accessToken = '', " +
           "u.gender = '', u.birthday = '', u.zipcode = '', u.addr = '', u.newAddr = '', u.addrDtl = '', " +
           "u.etc1 = '', u.etc2 = '', u.etc3 = '', u.etc4 = '', u.etc5 = '', u.dupinfo = '', u.oauthVendor = '', " +
           "u.status = -1 WHERE u.id = :userId")
    int deleteUser(@Param("userId") Long userId);
}
