// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/config/WebConfig.java
package kr.polytech.lms.legacy.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * 웹 MVC 설정
 * 정적 리소스 및 CORS 설정
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 정적 리소스 핸들러
        registry.addResourceHandler("/static/**")
                .addResourceLocations("classpath:/static/");

        // 공통 리소스 (CSS, JS, 이미지)
        registry.addResourceHandler("/common/**")
                .addResourceLocations("classpath:/static/common/");

        // HTML 파일
        registry.addResourceHandler("/html/**")
                .addResourceLocations("classpath:/static/html/");
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .maxAge(3600);
    }
}
