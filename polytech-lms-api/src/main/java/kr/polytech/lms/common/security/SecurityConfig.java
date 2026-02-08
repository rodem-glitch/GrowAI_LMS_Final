// polytech-lms-api/src/main/java/kr/polytech/lms/common/security/SecurityConfig.java
package kr.polytech.lms.common.security;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.header.writers.XXssProtectionHeaderWriter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

/**
 * Spring Security 설정
 * 행정안전부 시큐어코딩 가이드라인 준수
 * - XSS 방지
 * - CSRF 보호
 * - 세션 관리
 * - CORS 설정
 */
@Slf4j
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            // CORS 설정
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))

            // CSRF 보호 (REST API는 비활성화, 프로덕션에서는 토큰 기반 CSRF 권장)
            .csrf(AbstractHttpConfigurer::disable)

            // 세션 관리 (Stateless)
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )

            // 보안 헤더 설정
            .headers(headers -> headers
                // XSS 방지 헤더
                .xssProtection(xss -> xss
                    .headerValue(XXssProtectionHeaderWriter.HeaderValue.ENABLED_MODE_BLOCK)
                )
                // Content-Type 스니핑 방지
                .contentTypeOptions(contentType -> {})
                // Clickjacking 방지
                .frameOptions(frame -> frame.sameOrigin())
                // HSTS (HTTPS 강제)
                .httpStrictTransportSecurity(hsts ->
                    hsts.maxAgeInSeconds(31536000).includeSubDomains(true)
                )
            )

            // 인가 규칙
            .authorizeHttpRequests(auth -> auth
                // 헬스체크/메트릭스
                .requestMatchers("/actuator/**").permitAll()
                // 정적 리소스
                .requestMatchers("/static/**", "/css/**", "/js/**", "/images/**").permitAll()
                // API 엔드포인트 (개발 단계: 모두 허용)
                .requestMatchers("/api/**").permitAll()
                // 그 외
                .anyRequest().permitAll()
            );

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(List.of(
            "http://localhost:3000",    // React 개발 서버
            "http://localhost:5173",    // Vite 개발 서버
            "http://localhost:8081",    // API 서버
            "http://127.0.0.1:3000",
            "http://127.0.0.1:5173"
        ));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setExposedHeaders(List.of("Authorization", "Content-Type"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
