// polytech-lms-api/src/main/java/kr/polytech/lms/config/ConnectionPoolConfig.java
package kr.polytech.lms.config;

import com.zaxxer.hikari.HikariDataSource;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import javax.sql.DataSource;

/**
 * HikariCP 커넥션 풀 최적화 설정
 * 대규모 사용자 대응을 위한 설정
 */
@Configuration
public class ConnectionPoolConfig {

    @Value("${spring.datasource.url:jdbc:mysql://localhost:3306/lms}")
    private String jdbcUrl;

    @Value("${spring.datasource.username:root}")
    private String username;

    @Value("${spring.datasource.password:}")
    private String password;

    @Value("${spring.datasource.driver-class-name:com.mysql.cj.jdbc.Driver}")
    private String driverClassName;

    /**
     * 최적화된 HikariCP DataSource
     */
    @Bean
    @Primary
    @ConditionalOnProperty(name = "spring.datasource.hikari.enabled", havingValue = "true", matchIfMissing = true)
    public DataSource hikariDataSource() {
        HikariDataSource dataSource = new HikariDataSource();

        // 기본 연결 정보
        dataSource.setJdbcUrl(jdbcUrl);
        dataSource.setUsername(username);
        dataSource.setPassword(password);
        dataSource.setDriverClassName(driverClassName);

        // 풀 사이즈 설정 (CPU 코어 수 기반 최적화)
        int cpuCores = Runtime.getRuntime().availableProcessors();
        int poolSize = Math.max(10, cpuCores * 2 + 1);
        dataSource.setMaximumPoolSize(poolSize);
        dataSource.setMinimumIdle(cpuCores);

        // 커넥션 타임아웃 (30초)
        dataSource.setConnectionTimeout(30000);

        // 유휴 커넥션 타임아웃 (10분)
        dataSource.setIdleTimeout(600000);

        // 커넥션 최대 수명 (30분)
        dataSource.setMaxLifetime(1800000);

        // 커넥션 유효성 검사
        dataSource.setConnectionTestQuery("SELECT 1");

        // 커넥션 풀 이름
        dataSource.setPoolName("LmsHikariPool");

        // 누수 감지 (3분)
        dataSource.setLeakDetectionThreshold(180000);

        // 자동 커밋
        dataSource.setAutoCommit(true);

        // MySQL 최적화 옵션
        dataSource.addDataSourceProperty("cachePrepStmts", "true");
        dataSource.addDataSourceProperty("prepStmtCacheSize", "250");
        dataSource.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");
        dataSource.addDataSourceProperty("useServerPrepStmts", "true");
        dataSource.addDataSourceProperty("useLocalSessionState", "true");
        dataSource.addDataSourceProperty("rewriteBatchedStatements", "true");
        dataSource.addDataSourceProperty("cacheResultSetMetadata", "true");
        dataSource.addDataSourceProperty("cacheServerConfiguration", "true");
        dataSource.addDataSourceProperty("elideSetAutoCommits", "true");
        dataSource.addDataSourceProperty("maintainTimeStats", "false");

        return dataSource;
    }
}
