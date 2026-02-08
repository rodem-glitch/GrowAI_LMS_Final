// polytech-lms-api/src/main/java/kr/polytech/lms/config/PerformanceConfig.java
package kr.polytech.lms.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;
import java.util.concurrent.TimeUnit;

/**
 * 성능 최적화 설정
 * 캐시, 비동기 처리, 스레드 풀 설정
 */
@Configuration
@EnableCaching
@EnableAsync
public class PerformanceConfig {

    /**
     * Caffeine 캐시 매니저
     * Redis 없이 로컬 캐시 사용
     */
    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager();
        cacheManager.setCaffeine(Caffeine.newBuilder()
            // 최대 캐시 항목 수
            .maximumSize(10000)
            // 쓰기 후 만료 시간
            .expireAfterWrite(10, TimeUnit.MINUTES)
            // 접근 후 만료 시간
            .expireAfterAccess(5, TimeUnit.MINUTES)
            // 통계 수집
            .recordStats()
        );
        return cacheManager;
    }

    /**
     * 비동기 작업용 스레드 풀
     */
    @Bean(name = "taskExecutor")
    public Executor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        // 코어 스레드 수
        executor.setCorePoolSize(10);
        // 최대 스레드 수
        executor.setMaxPoolSize(50);
        // 큐 용량
        executor.setQueueCapacity(500);
        // 스레드 이름 접두사
        executor.setThreadNamePrefix("LmsAsync-");
        // 종료 대기
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(60);
        executor.initialize();
        return executor;
    }

    /**
     * 이메일/알림 전송용 스레드 풀
     */
    @Bean(name = "notificationExecutor")
    public Executor notificationExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(5);
        executor.setMaxPoolSize(20);
        executor.setQueueCapacity(1000);
        executor.setThreadNamePrefix("LmsNotify-");
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(120);
        executor.initialize();
        return executor;
    }

    /**
     * 배치 작업용 스레드 풀
     */
    @Bean(name = "batchExecutor")
    public Executor batchExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(5);
        executor.setQueueCapacity(100);
        executor.setThreadNamePrefix("LmsBatch-");
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(300);
        executor.initialize();
        return executor;
    }
}
