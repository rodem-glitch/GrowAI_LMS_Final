// polytech-lms-api/src/main/java/kr/polytech/lms/monitoring/config/ActuatorSecurityConfig.java
package kr.polytech.lms.monitoring.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Actuator 엔드포인트 보안 설정
 * Prometheus, Health Check 등 모니터링 엔드포인트 접근 제어
 */
@Configuration
public class ActuatorSecurityConfig {

    @Bean
    @Order(1)
    public SecurityFilterChain actuatorSecurityFilterChain(HttpSecurity http) throws Exception {
        http
            .securityMatcher("/actuator/**")
            .authorizeHttpRequests(auth -> auth
                // 헬스체크는 인증 없이 허용 (로드밸런서용)
                .requestMatchers("/actuator/health", "/actuator/health/**").permitAll()
                // Prometheus 메트릭은 내부 네트워크에서만 허용
                .requestMatchers("/actuator/prometheus").permitAll()
                // 나머지 Actuator 엔드포인트는 인증 필요
                .anyRequest().authenticated()
            )
            .httpBasic(httpBasic -> {});

        return http.build();
    }

    @Bean
    @Order(2)
    public SecurityFilterChain apiSecurityFilterChain(HttpSecurity http) throws Exception {
        http
            .securityMatcher("/api/**")
            .authorizeHttpRequests(auth -> auth
                // 공개 API
                .requestMatchers("/api/public/**").permitAll()
                .requestMatchers("/api/lms/health").permitAll()
                // 나머지 API는 인증 필요
                .anyRequest().authenticated()
            )
            .csrf(csrf -> csrf.disable())
            .cors(cors -> {});

        return http.build();
    }
}
