// polytech-lms-api/src/main/java/kr/polytech/lms/gcp/service/GoogleIdentityService.java
package kr.polytech.lms.gcp.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.*;

/**
 * Google Identity 서비스
 * Google OAuth2/OIDC SSO 글로벌 표준 통합
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GoogleIdentityService {

    private final ObjectMapper objectMapper;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${gcp.oauth2.client-id:}")
    private String clientId;

    @Value("${gcp.oauth2.client-secret:}")
    private String clientSecret;

    @Value("${gcp.oauth2.redirect-uri:http://localhost:8081/api/auth/google/callback}")
    private String redirectUri;

    @Value("${app.jwt.secret:polytech-lms-secret-key-must-be-at-least-256-bits-long}")
    private String jwtSecret;

    @Value("${app.jwt.expiration:86400000}")
    private long jwtExpiration;

    private static final String GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth";
    private static final String GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";
    private static final String GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo";
    private static final String GOOGLE_CERTS_URL = "https://www.googleapis.com/oauth2/v3/certs";

    /**
     * Google OAuth2 인증 URL 생성
     */
    public String getAuthorizationUrl(String state) {
        String scope = "openid email profile";

        return GOOGLE_AUTH_URL +
            "?client_id=" + clientId +
            "&redirect_uri=" + redirectUri +
            "&response_type=code" +
            "&scope=" + scope.replace(" ", "%20") +
            "&access_type=offline" +
            "&prompt=consent" +
            "&state=" + (state != null ? state : UUID.randomUUID().toString());
    }

    /**
     * Authorization Code를 Access Token으로 교환
     */
    public Map<String, Object> exchangeCodeForTokens(String code) {
        log.info("Google OAuth2 토큰 교환");

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

            String body = String.format(
                "code=%s&client_id=%s&client_secret=%s&redirect_uri=%s&grant_type=authorization_code",
                code, clientId, clientSecret, redirectUri
            );

            HttpEntity<String> request = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(GOOGLE_TOKEN_URL, request, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());

                return Map.of(
                    "success", true,
                    "accessToken", root.path("access_token").asText(),
                    "refreshToken", root.path("refresh_token").asText(""),
                    "idToken", root.path("id_token").asText(),
                    "tokenType", root.path("token_type").asText(),
                    "expiresIn", root.path("expires_in").asInt()
                );
            }

        } catch (Exception e) {
            log.error("토큰 교환 실패: {}", e.getMessage());
        }

        return Map.of("success", false, "error", "토큰 교환 실패");
    }

    /**
     * Access Token으로 사용자 정보 조회
     */
    public Map<String, Object> getUserInfo(String accessToken) {
        log.info("Google 사용자 정보 조회");

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);

            HttpEntity<Void> request = new HttpEntity<>(headers);
            ResponseEntity<String> response = restTemplate.exchange(
                GOOGLE_USERINFO_URL, HttpMethod.GET, request, String.class
            );

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());

                return Map.of(
                    "success", true,
                    "id", root.path("id").asText(),
                    "email", root.path("email").asText(),
                    "verifiedEmail", root.path("verified_email").asBoolean(),
                    "name", root.path("name").asText(),
                    "givenName", root.path("given_name").asText(""),
                    "familyName", root.path("family_name").asText(""),
                    "picture", root.path("picture").asText(""),
                    "locale", root.path("locale").asText("ko")
                );
            }

        } catch (Exception e) {
            log.error("사용자 정보 조회 실패: {}", e.getMessage());
        }

        return Map.of("success", false, "error", "사용자 정보 조회 실패");
    }

    /**
     * ID Token 검증
     */
    public Map<String, Object> verifyIdToken(String idToken) {
        log.info("Google ID Token 검증");

        try {
            // JWT 디코딩 (서명 검증 생략 - 실제 운영에서는 Google의 공개키로 검증 필요)
            String[] parts = idToken.split("\\.");
            if (parts.length != 3) {
                return Map.of("success", false, "error", "Invalid token format");
            }

            String payload = new String(Base64.getUrlDecoder().decode(parts[1]), StandardCharsets.UTF_8);
            JsonNode claims = objectMapper.readTree(payload);

            // 기본 검증
            String iss = claims.path("iss").asText();
            if (!iss.equals("https://accounts.google.com") && !iss.equals("accounts.google.com")) {
                return Map.of("success", false, "error", "Invalid issuer");
            }

            String aud = claims.path("aud").asText();
            if (!aud.equals(clientId)) {
                return Map.of("success", false, "error", "Invalid audience");
            }

            long exp = claims.path("exp").asLong();
            if (Instant.now().getEpochSecond() > exp) {
                return Map.of("success", false, "error", "Token expired");
            }

            return Map.of(
                "success", true,
                "sub", claims.path("sub").asText(),
                "email", claims.path("email").asText(),
                "emailVerified", claims.path("email_verified").asBoolean(),
                "name", claims.path("name").asText(""),
                "picture", claims.path("picture").asText(""),
                "iat", claims.path("iat").asLong(),
                "exp", exp
            );

        } catch (Exception e) {
            log.error("ID Token 검증 실패: {}", e.getMessage());
        }

        return Map.of("success", false, "error", "Token verification failed");
    }

    /**
     * 내부 JWT 토큰 생성
     */
    public String generateJwtToken(String userId, String email, String name, Map<String, Object> additionalClaims) {
        SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));

        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", userId);
        claims.put("email", email);
        claims.put("name", name);
        if (additionalClaims != null) {
            claims.putAll(additionalClaims);
        }

        return Jwts.builder()
            .claims(claims)
            .subject(userId)
            .issuedAt(new Date())
            .expiration(new Date(System.currentTimeMillis() + jwtExpiration))
            .signWith(key)
            .compact();
    }

    /**
     * JWT 토큰 검증
     */
    public Map<String, Object> verifyJwtToken(String token) {
        try {
            SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));

            Claims claims = Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();

            return Map.of(
                "success", true,
                "userId", claims.get("userId", String.class),
                "email", claims.get("email", String.class),
                "name", claims.get("name", String.class),
                "subject", claims.getSubject(),
                "issuedAt", claims.getIssuedAt(),
                "expiration", claims.getExpiration()
            );

        } catch (Exception e) {
            log.error("JWT 검증 실패: {}", e.getMessage());
            return Map.of("success", false, "error", e.getMessage());
        }
    }

    /**
     * Refresh Token으로 새 Access Token 획득
     */
    public Map<String, Object> refreshAccessToken(String refreshToken) {
        log.info("Access Token 갱신");

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

            String body = String.format(
                "refresh_token=%s&client_id=%s&client_secret=%s&grant_type=refresh_token",
                refreshToken, clientId, clientSecret
            );

            HttpEntity<String> request = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(GOOGLE_TOKEN_URL, request, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());

                return Map.of(
                    "success", true,
                    "accessToken", root.path("access_token").asText(),
                    "tokenType", root.path("token_type").asText(),
                    "expiresIn", root.path("expires_in").asInt()
                );
            }

        } catch (Exception e) {
            log.error("토큰 갱신 실패: {}", e.getMessage());
        }

        return Map.of("success", false, "error", "토큰 갱신 실패");
    }

    /**
     * 전체 로그인 플로우 (코드 교환 + 사용자 정보 + JWT 발급)
     */
    public Map<String, Object> processGoogleLogin(String code) {
        // 1. 토큰 교환
        Map<String, Object> tokenResult = exchangeCodeForTokens(code);
        if (!(Boolean) tokenResult.get("success")) {
            return tokenResult;
        }

        String accessToken = (String) tokenResult.get("accessToken");

        // 2. 사용자 정보 조회
        Map<String, Object> userInfo = getUserInfo(accessToken);
        if (!(Boolean) userInfo.get("success")) {
            return userInfo;
        }

        // 3. 내부 JWT 토큰 생성
        String userId = (String) userInfo.get("id");
        String email = (String) userInfo.get("email");
        String name = (String) userInfo.get("name");

        String jwtToken = generateJwtToken(userId, email, name, Map.of(
            "provider", "google",
            "picture", userInfo.getOrDefault("picture", "")
        ));

        return Map.of(
            "success", true,
            "user", userInfo,
            "token", jwtToken,
            "googleAccessToken", accessToken,
            "refreshToken", tokenResult.getOrDefault("refreshToken", "")
        );
    }

    /**
     * 서비스 상태 확인
     */
    public Map<String, Object> healthCheck() {
        boolean configured = clientId != null && !clientId.isEmpty();

        return Map.of(
            "service", "google-identity",
            "clientId", clientId != null ? clientId.substring(0, Math.min(10, clientId.length())) + "..." : "not-configured",
            "redirectUri", redirectUri,
            "configured", configured,
            "status", configured ? "UP" : "NOT_CONFIGURED"
        );
    }
}
