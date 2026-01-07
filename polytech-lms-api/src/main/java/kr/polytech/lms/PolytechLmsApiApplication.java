package kr.polytech.lms;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class PolytechLmsApiApplication {
    public static void main(String[] args) {
        // 왜: `@ConfigurationProperties`(예: KOSIS 설정)을 패키지 스캔으로 자동 등록하기 위해 사용합니다.
        SpringApplication.run(PolytechLmsApiApplication.class, args);
    }
}
