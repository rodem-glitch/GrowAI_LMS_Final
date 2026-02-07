package kr.polytech.lms;

import malgnsoft.util.Aes256; // Added import
import org.springframework.beans.factory.annotation.Value; // Added import
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.context.annotation.Bean; // Added import
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@ConfigurationPropertiesScan
@EnableScheduling
public class PolytechLmsApiApplication {
    public static void main(String[] args) {
        // 왜: `@ConfigurationProperties`(예: kollus.*, KOSIS 설정 등)을 패키지 스캔으로 자동 등록하기 위해 사용합니다.
        SpringApplication.run(PolytechLmsApiApplication.class, args);
    }

    // Bean definition for Aes256
    @Bean
    public Aes256 aes256(
            @Value("${app.encryption.aes.key}") String key,
            @Value("${app.encryption.aes.iv}") String iv
    ) {
        return new Aes256(key, iv);
    }
}