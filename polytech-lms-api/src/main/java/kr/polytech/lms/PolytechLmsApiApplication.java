package kr.polytech.lms;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@ConfigurationPropertiesScan
@EnableScheduling
public class PolytechLmsApiApplication {
    public static void main(String[] args) {
        // 왜: `@ConfigurationProperties`(예: kollus.*)를 패키지 전역에서 자동으로 찾아서 등록하기 위함입니다.
        SpringApplication.run(PolytechLmsApiApplication.class, args);
    }
}
