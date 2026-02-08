// D:\Real_one_stop_service\GoogleAI\backend\src\main\java\kr\polytech\epoly\EpolyAiApplication.java
package kr.polytech.epoly;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * epoly AI LMS 백엔드 애플리케이션 진입점.
 *
 * <p>한국폴리텍대학 AI 기반 학습관리시스템(LMS) 백엔드 서버입니다.
 * Spring Boot 3.2 + Spring AI + Google Gemini 기반으로 구성됩니다.</p>
 *
 * <ul>
 *   <li>{@code @EnableCaching} - Caffeine 기반 캐시 활성화 (과정/사용자 조회 캐싱)</li>
 *   <li>{@code @EnableScheduling} - 스케줄 작업 활성화 (학사 동기화, 배치 처리 등)</li>
 * </ul>
 */
@SpringBootApplication
@EnableCaching
@EnableScheduling
public class EpolyAiApplication {

    public static void main(String[] args) {
        SpringApplication.run(EpolyAiApplication.class, args);
    }
}
