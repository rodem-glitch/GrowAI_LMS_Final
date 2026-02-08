// config/JwtTokenProvider.java — JWT 토큰 발급/검증
package kr.polytech.epoly.config;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.List;

@Slf4j
@Component
public class JwtTokenProvider {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.access-token-validity:3600000}")
    private long accessTokenValidity;

    @Value("${jwt.refresh-token-validity:604800000}")
    private long refreshTokenValidity;

    private SecretKey key;

    @PostConstruct
    protected void init() {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    /** 액세스 토큰 생성 */
    public String createAccessToken(String userId, String role) {
        return createToken(userId, role, accessTokenValidity);
    }

    /** 리프레시 토큰 생성 */
    public String createRefreshToken(String userId, String role) {
        return createToken(userId, role, refreshTokenValidity);
    }

    private String createToken(String userId, String role, long validity) {
        Date now = new Date();
        return Jwts.builder()
                .subject(userId)
                .claim("role", role)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + validity))
                .signWith(key, Jwts.SIG.HS256)
                .compact();
    }

    /** 토큰에서 사용자 ID 추출 */
    public String getUserId(String token) {
        return parseClaims(token).getSubject();
    }

    /** 토큰에서 역할 추출 */
    public String getRole(String token) {
        return parseClaims(token).get("role", String.class);
    }

    /** 토큰 유효성 검증 */
    public boolean validateToken(String token) {
        try {
            parseClaims(token);
            return true;
        } catch (ExpiredJwtException e) {
            log.warn("만료된 JWT 토큰");
        } catch (JwtException e) {
            log.warn("유효하지 않은 JWT 토큰: {}", e.getMessage());
        }
        return false;
    }

    /** Spring Security Authentication 객체 생성 */
    public Authentication getAuthentication(String token) {
        String userId = getUserId(token);
        String role = getRole(token);
        List<SimpleGrantedAuthority> authorities = List.of(new SimpleGrantedAuthority("ROLE_" + role));
        return new UsernamePasswordAuthenticationToken(userId, null, authorities);
    }

    private Claims parseClaims(String token) {
        return Jwts.parser().verifyWith(key).build()
                .parseSignedClaims(token).getPayload();
    }
}
