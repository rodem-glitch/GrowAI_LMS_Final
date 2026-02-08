// user/repository/UserRepository.java — 사용자 레포지토리
package kr.polytech.epoly.user.repository;

import kr.polytech.epoly.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByUserId(String userId);

    Optional<User> findByPolyMemberId(String polyMemberId);

    boolean existsByUserId(String userId);

    List<User> findByUserType(String userType);

    List<User> findByCampus(String campus);

    @Query("SELECT u FROM User u WHERE u.department = :dept AND u.userType = 'STUDENT' AND u.status = 'ACTIVE'")
    List<User> findActiveStudentsByDepartment(@Param("dept") String department);

    @Query("SELECT COUNT(u) FROM User u WHERE u.userType = :type AND u.status = 'ACTIVE'")
    long countByUserTypeAndActive(@Param("type") String userType);

    @Query("SELECT u FROM User u WHERE u.name LIKE %:keyword% OR u.userId LIKE %:keyword%")
    List<User> searchByKeyword(@Param("keyword") String keyword);
}
