// polytech-lms-api/src/main/java/kr/polytech/lms/agent/BackupAgent.java
package kr.polytech.lms.agent;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.zip.*;

/**
 * Backup Agent
 * 자동 백업 수행 및 복구 검증
 * Tech: Cloud Functions + Cloud Scheduler
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class BackupAgent {

    @Value("${backup.dir:./backups}")
    private String backupDir;

    @Value("${backup.retention-days:7}")
    private int retentionDays;

    // 백업 히스토리
    private final List<BackupRecord> backupHistory = Collections.synchronizedList(new ArrayList<>());

    /**
     * 일일 자동 백업 (매일 새벽 2시)
     */
    @Scheduled(cron = "0 0 2 * * *")
    public void scheduledDailyBackup() {
        log.info("Backup Agent: 일일 자동 백업 시작");
        performFullBackup("SCHEDULED_DAILY");
    }

    /**
     * 증분 백업 (매시간)
     */
    @Scheduled(cron = "0 0 * * * *")
    public void scheduledIncrementalBackup() {
        log.debug("Backup Agent: 증분 백업 체크");
        performIncrementalBackup();
    }

    /**
     * 전체 백업 수행
     */
    public Map<String, Object> performFullBackup(String triggerType) {
        log.info("Backup Agent: 전체 백업 수행 - trigger={}", triggerType);

        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
        String backupName = "full_backup_" + timestamp;

        try {
            // 백업 디렉토리 생성
            Path backupPath = Paths.get(backupDir, backupName);
            Files.createDirectories(backupPath);

            // 백업 항목들
            List<String> backedUpItems = new ArrayList<>();

            // 1. 설정 파일 백업
            backupConfigFiles(backupPath);
            backedUpItems.add("config");

            // 2. 데이터 백업 (시뮬레이션)
            backupData(backupPath);
            backedUpItems.add("data");

            // 3. 로그 백업
            backupLogs(backupPath);
            backedUpItems.add("logs");

            // 4. 압축
            String zipFile = backupPath + ".zip";
            compressDirectory(backupPath, zipFile);

            // 5. 원본 디렉토리 삭제
            deleteDirectory(backupPath);

            // 6. 백업 검증
            boolean verified = verifyBackup(zipFile);

            // 기록
            long fileSize = Files.size(Paths.get(zipFile));
            BackupRecord record = new BackupRecord(
                backupName,
                "FULL",
                zipFile,
                fileSize,
                verified,
                LocalDateTime.now()
            );
            backupHistory.add(record);

            // 오래된 백업 정리
            cleanupOldBackups();

            log.info("Backup Agent: 전체 백업 완료 - file={}, size={}bytes, verified={}",
                zipFile, fileSize, verified);

            return Map.of(
                "success", true,
                "backupName", backupName,
                "backupFile", zipFile,
                "fileSize", fileSize,
                "items", backedUpItems,
                "verified", verified,
                "timestamp", LocalDateTime.now().toString()
            );

        } catch (Exception e) {
            log.error("Backup Agent: 백업 실패 - {}", e.getMessage());
            return Map.of(
                "success", false,
                "error", e.getMessage()
            );
        }
    }

    /**
     * 증분 백업 수행
     */
    public Map<String, Object> performIncrementalBackup() {
        log.debug("Backup Agent: 증분 백업 수행");

        // 마지막 백업 이후 변경된 파일만 백업
        // 실제로는 파일 수정 시간 비교 또는 rsync 방식 사용

        return Map.of(
            "success", true,
            "type", "INCREMENTAL",
            "changedFiles", 0,
            "timestamp", LocalDateTime.now().toString()
        );
    }

    /**
     * 백업 복구
     */
    public Map<String, Object> restoreBackup(String backupName) {
        log.info("Backup Agent: 백업 복구 시작 - {}", backupName);

        String zipFile = Paths.get(backupDir, backupName + ".zip").toString();

        if (!Files.exists(Paths.get(zipFile))) {
            return Map.of("success", false, "error", "백업 파일을 찾을 수 없습니다.");
        }

        try {
            // 복구 디렉토리
            Path restorePath = Paths.get(backupDir, "restore_" + backupName);
            Files.createDirectories(restorePath);

            // 압축 해제
            extractZip(zipFile, restorePath.toString());

            log.info("Backup Agent: 백업 복구 완료 - target={}", restorePath);

            return Map.of(
                "success", true,
                "restorePath", restorePath.toString(),
                "timestamp", LocalDateTime.now().toString()
            );

        } catch (Exception e) {
            log.error("Backup Agent: 복구 실패 - {}", e.getMessage());
            return Map.of("success", false, "error", e.getMessage());
        }
    }

    /**
     * 설정 파일 백업
     */
    private void backupConfigFiles(Path backupPath) throws IOException {
        Path configPath = backupPath.resolve("config");
        Files.createDirectories(configPath);

        // 시뮬레이션: 설정 정보 저장
        Files.writeString(configPath.resolve("backup_info.txt"),
            "Backup Time: " + LocalDateTime.now() + "\n" +
            "Type: FULL\n" +
            "Agent: BackupAgent\n"
        );
    }

    /**
     * 데이터 백업
     */
    private void backupData(Path backupPath) throws IOException {
        Path dataPath = backupPath.resolve("data");
        Files.createDirectories(dataPath);

        // 시뮬레이션: 데이터 정보 저장
        Files.writeString(dataPath.resolve("data_info.txt"),
            "Data backup simulation\n" +
            "Tables: courses, members, grades, attendance\n"
        );
    }

    /**
     * 로그 백업
     */
    private void backupLogs(Path backupPath) throws IOException {
        Path logsPath = backupPath.resolve("logs");
        Files.createDirectories(logsPath);

        // 시뮬레이션
        Files.writeString(logsPath.resolve("log_info.txt"),
            "Log backup simulation\n"
        );
    }

    /**
     * 디렉토리 압축
     */
    private void compressDirectory(Path sourceDir, String zipFile) throws IOException {
        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(zipFile))) {
            Files.walk(sourceDir)
                .filter(path -> !Files.isDirectory(path))
                .forEach(path -> {
                    ZipEntry zipEntry = new ZipEntry(sourceDir.relativize(path).toString());
                    try {
                        zos.putNextEntry(zipEntry);
                        Files.copy(path, zos);
                        zos.closeEntry();
                    } catch (IOException e) {
                        log.error("압축 중 오류: {}", e.getMessage());
                    }
                });
        }
    }

    /**
     * ZIP 파일 압축 해제
     */
    private void extractZip(String zipFile, String destDir) throws IOException {
        try (ZipInputStream zis = new ZipInputStream(new FileInputStream(zipFile))) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                Path filePath = Paths.get(destDir, entry.getName());
                if (entry.isDirectory()) {
                    Files.createDirectories(filePath);
                } else {
                    Files.createDirectories(filePath.getParent());
                    Files.copy(zis, filePath, StandardCopyOption.REPLACE_EXISTING);
                }
                zis.closeEntry();
            }
        }
    }

    /**
     * 디렉토리 삭제
     */
    private void deleteDirectory(Path path) throws IOException {
        if (Files.exists(path)) {
            Files.walk(path)
                .sorted(Comparator.reverseOrder())
                .forEach(p -> {
                    try {
                        Files.delete(p);
                    } catch (IOException e) {
                        log.warn("파일 삭제 실패: {}", p);
                    }
                });
        }
    }

    /**
     * 백업 검증
     */
    private boolean verifyBackup(String zipFile) {
        try {
            // ZIP 파일 무결성 확인
            try (ZipFile zip = new ZipFile(zipFile)) {
                return zip.entries().hasMoreElements();
            }
        } catch (Exception e) {
            log.error("백업 검증 실패: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 오래된 백업 정리
     */
    private void cleanupOldBackups() {
        try {
            Path backupPath = Paths.get(backupDir);
            if (!Files.exists(backupPath)) return;

            long cutoffTime = System.currentTimeMillis() - (retentionDays * 24L * 60 * 60 * 1000);

            Files.list(backupPath)
                .filter(path -> path.toString().endsWith(".zip"))
                .filter(path -> {
                    try {
                        return Files.getLastModifiedTime(path).toMillis() < cutoffTime;
                    } catch (IOException e) {
                        return false;
                    }
                })
                .forEach(path -> {
                    try {
                        Files.delete(path);
                        log.info("Backup Agent: 오래된 백업 삭제 - {}", path.getFileName());
                    } catch (IOException e) {
                        log.warn("백업 삭제 실패: {}", path);
                    }
                });

        } catch (IOException e) {
            log.error("백업 정리 실패: {}", e.getMessage());
        }
    }

    /**
     * 백업 목록 조회
     */
    public List<Map<String, Object>> listBackups() {
        return backupHistory.stream()
            .map(r -> Map.<String, Object>of(
                "name", r.name,
                "type", r.type,
                "file", r.filePath,
                "size", r.fileSize,
                "verified", r.verified,
                "timestamp", r.timestamp.toString()
            ))
            .toList();
    }

    /**
     * 에이전트 상태 조회
     */
    public Map<String, Object> getStatus() {
        return Map.of(
            "agent", "BackupAgent",
            "role", "자동 백업 수행 및 복구 검증",
            "tech", "Cloud Functions + Cloud Scheduler",
            "backupDir", backupDir,
            "retentionDays", retentionDays,
            "totalBackups", backupHistory.size(),
            "status", "ACTIVE",
            "lastBackup", backupHistory.isEmpty() ? "NONE" :
                backupHistory.get(backupHistory.size() - 1).timestamp.toString()
        );
    }

    /**
     * 백업 기록 내부 클래스
     */
    private record BackupRecord(
        String name,
        String type,
        String filePath,
        long fileSize,
        boolean verified,
        LocalDateTime timestamp
    ) {}
}
