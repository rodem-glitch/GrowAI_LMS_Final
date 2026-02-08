// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/entity/User.java
package kr.polytech.lms.legacy.entity;

import jakarta.persistence.*;
import lombok.*;
import kr.polytech.lms.legacy.enums.UserStatus;
import kr.polytech.lms.legacy.enums.UserKind;

/**
 * 사용자 엔티티
 * 레거시 TB_USER 테이블 매핑
 */
@Entity
@Table(name = "TB_USER")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "site_id", nullable = false)
    private Long siteId;

    @Column(name = "login_id", length = 50)
    private String loginId;

    @Column(name = "passwd", length = 200)
    private String passwd;

    @Column(name = "user_nm", length = 50)
    private String userNm;

    @Column(name = "user_kind", length = 1)
    private String userKind;

    @Column(name = "status")
    private Integer status;

    @Column(name = "email", length = 100)
    private String email;

    @Column(name = "mobile", length = 200)
    private String mobile;

    @Column(name = "gender", length = 1)
    private String gender;

    @Column(name = "birthday", length = 8)
    private String birthday;

    @Column(name = "zipcode", length = 10)
    private String zipcode;

    @Column(name = "addr", length = 200)
    private String addr;

    @Column(name = "new_addr", length = 200)
    private String newAddr;

    @Column(name = "addr_dtl", length = 200)
    private String addrDtl;

    @Column(name = "dept_id")
    private Long deptId;

    @Column(name = "access_token", length = 200)
    private String accessToken;

    @Column(name = "dupinfo", length = 200)
    private String dupinfo;

    @Column(name = "oauth_vendor", length = 50)
    private String oauthVendor;

    @Column(name = "reg_date", length = 14)
    private String regDate;

    @Column(name = "conn_date", length = 14)
    private String connDate;

    @Column(name = "sleep_date", length = 14)
    private String sleepDate;

    @Column(name = "etc1", length = 200)
    private String etc1;

    @Column(name = "etc2", length = 200)
    private String etc2;

    @Column(name = "etc3", length = 200)
    private String etc3;

    @Column(name = "etc4", length = 200)
    private String etc4;

    @Column(name = "etc5", length = 200)
    private String etc5;

    // Enum 변환 메서드
    @Transient
    public UserStatus getUserStatusEnum() {
        return UserStatus.fromCode(String.valueOf(status));
    }

    @Transient
    public UserKind getUserKindEnum() {
        return UserKind.fromCode(userKind);
    }

    @Transient
    public boolean isActive() {
        return status != null && status == 1;
    }

    @Transient
    public boolean isAdmin() {
        return getUserKindEnum().isAdmin();
    }
}
