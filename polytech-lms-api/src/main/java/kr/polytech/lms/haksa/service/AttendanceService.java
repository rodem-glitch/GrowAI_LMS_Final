// polytech-lms-api/src/main/java/kr/polytech/lms/haksa/service/AttendanceService.java
package kr.polytech.lms.haksa.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 출결 관리 서비스
 * RFP 항목 #1: 차시 유효기간 (출결)
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AttendanceService {

    private final MockDataService mockDataService;

    // 출석 기록 저장소 (courseCode:memberKey:week -> AttendanceRecord)
    private final Map<String, AttendanceRecord> attendanceRecords = new ConcurrentHashMap<>();

    // 지각 3회 = 결석 1회 기준
    private static final int LATE_TO_ABSENT_THRESHOLD = 3;

    /**
     * 차시 유효기간 조회
     */
    public Map<String, Object> getLessonValidity(String courseCode, int week) {
        Optional<Map<String, Object>> lectPlanOpt = mockDataService.getLectPlan(courseCode, week);

        if (lectPlanOpt.isEmpty()) {
            return Map.of("valid", false, "reason", "차시 정보 없음");
        }

        Map<String, Object> lectPlan = lectPlanOpt.get();
        LocalDateTime now = LocalDateTime.now();

        // 유효기간 파싱
        String validFromStr = (String) lectPlan.get("VALID_FROM");
        String validToStr = (String) lectPlan.get("VALID_TO");

        LocalDateTime validFrom = LocalDateTime.parse(validFromStr);
        LocalDateTime validTo = LocalDateTime.parse(validToStr);

        boolean isValid = now.isAfter(validFrom) && now.isBefore(validTo);
        String status = isValid ? "OPEN" : (now.isBefore(validFrom) ? "NOT_STARTED" : "EXPIRED");

        return Map.of(
            "courseCode", courseCode,
            "week", week,
            "title", lectPlan.get("LSN_TITLE"),
            "validFrom", validFromStr,
            "validTo", validToStr,
            "currentTime", now.toString(),
            "isValid", isValid,
            "status", status,
            "remainingTime", calculateRemainingTime(now, validTo)
        );
    }

    /**
     * 출석 체크
     */
    public Map<String, Object> checkAttendance(String courseCode, String memberKey, int week) {
        // 유효기간 확인
        Map<String, Object> validity = getLessonValidity(courseCode, week);

        if (!(Boolean) validity.get("isValid")) {
            String status = (String) validity.get("status");
            if ("EXPIRED".equals(status)) {
                // 유효기간 만료 시 결석 처리
                return recordAttendance(courseCode, memberKey, week, "ABSENT", "유효기간 만료");
            } else {
                return Map.of(
                    "success", false,
                    "reason", "아직 출석 체크 기간이 아닙니다.",
                    "validFrom", validity.get("validFrom")
                );
            }
        }

        // 정상 출석 처리
        return recordAttendance(courseCode, memberKey, week, "PRESENT", null);
    }

    /**
     * 출석 기록
     */
    private Map<String, Object> recordAttendance(String courseCode, String memberKey,
                                                   int week, String status, String reason) {
        String key = courseCode + ":" + memberKey + ":" + week;
        LocalDateTime now = LocalDateTime.now();

        AttendanceRecord record = new AttendanceRecord(
            courseCode, memberKey, week, status, now, reason
        );
        attendanceRecords.put(key, record);

        log.info("출석 기록: {} - {} - week{} - {}", courseCode, memberKey, week, status);

        return Map.of(
            "success", true,
            "courseCode", courseCode,
            "memberKey", memberKey,
            "week", week,
            "status", status,
            "timestamp", now.toString(),
            "reason", reason != null ? reason : ""
        );
    }

    /**
     * 학생별 출석 현황 조회
     */
    public Map<String, Object> getStudentAttendance(String courseCode, String memberKey) {
        List<Map<String, Object>> weeklyPlans = mockDataService.getLectPlansByCourse(courseCode);
        List<Map<String, Object>> attendance = new ArrayList<>();

        int present = 0, late = 0, absent = 0;

        for (Map<String, Object> plan : weeklyPlans) {
            int week = (Integer) plan.get("LSN_WEKORD");
            String key = courseCode + ":" + memberKey + ":" + week;

            AttendanceRecord record = attendanceRecords.get(key);
            String status = record != null ? record.status : "NOT_CHECKED";

            if ("PRESENT".equals(status)) present++;
            else if ("LATE".equals(status)) late++;
            else if ("ABSENT".equals(status)) absent++;

            attendance.add(Map.of(
                "week", week,
                "title", plan.get("LSN_TITLE"),
                "status", status,
                "validFrom", plan.get("VALID_FROM"),
                "validTo", plan.get("VALID_TO")
            ));
        }

        // 지각 3회 = 결석 1회 계산
        int effectiveAbsent = absent + (late / LATE_TO_ABSENT_THRESHOLD);
        double attendanceRate = weeklyPlans.isEmpty() ? 0 :
            (double) (present + late) / weeklyPlans.size() * 100;

        return Map.of(
            "courseCode", courseCode,
            "memberKey", memberKey,
            "attendance", attendance,
            "summary", Map.of(
                "total", weeklyPlans.size(),
                "present", present,
                "late", late,
                "absent", absent,
                "effectiveAbsent", effectiveAbsent,
                "attendanceRate", Math.round(attendanceRate * 10) / 10.0
            )
        );
    }

    /**
     * 강좌별 출석 현황 조회 (교수자용)
     */
    public Map<String, Object> getCourseAttendance(String courseCode) {
        List<Map<String, Object>> students = mockDataService.getStudentsByCourse(courseCode);
        List<Map<String, Object>> studentAttendance = new ArrayList<>();

        int totalPresent = 0, totalLate = 0, totalAbsent = 0;

        for (Map<String, Object> student : students) {
            String memberKey = (String) student.get("MEMBER_KEY");
            Map<String, Object> attendance = getStudentAttendance(courseCode, memberKey);

            // 학생 정보 추가
            Optional<Map<String, Object>> memberOpt = mockDataService.getMemberByKey(memberKey);
            if (memberOpt.isPresent()) {
                Map<String, Object> member = memberOpt.get();
                Map<String, Object> summary = (Map<String, Object>) attendance.get("summary");

                studentAttendance.add(Map.of(
                    "memberKey", memberKey,
                    "studentNo", student.get("STUDENT_NO"),
                    "name", member.get("KOR_NAME"),
                    "className", student.get("BUNBAN_CODE"),
                    "summary", summary
                ));

                totalPresent += (Integer) summary.get("present");
                totalLate += (Integer) summary.get("late");
                totalAbsent += (Integer) summary.get("absent");
            }
        }

        return Map.of(
            "courseCode", courseCode,
            "students", studentAttendance,
            "totalSummary", Map.of(
                "totalStudents", students.size(),
                "totalPresent", totalPresent,
                "totalLate", totalLate,
                "totalAbsent", totalAbsent
            )
        );
    }

    /**
     * 유효기간 만료 시 자동 결석 처리 배치
     */
    @Scheduled(cron = "0 0 * * * *") // 매시간 실행
    public void processExpiredLessons() {
        log.info("만료된 차시 결석 처리 시작...");

        List<Map<String, Object>> courses = mockDataService.getAllCourses();
        int processedCount = 0;

        for (Map<String, Object> course : courses) {
            String courseCode = (String) course.get("COURSE_CODE");
            List<Map<String, Object>> plans = mockDataService.getLectPlansByCourse(courseCode);

            for (Map<String, Object> plan : plans) {
                int week = (Integer) plan.get("LSN_WEKORD");
                Map<String, Object> validity = getLessonValidity(courseCode, week);

                if ("EXPIRED".equals(validity.get("status"))) {
                    // 미체크 학생들 결석 처리
                    List<Map<String, Object>> students = mockDataService.getStudentsByCourse(courseCode);
                    for (Map<String, Object> student : students) {
                        String memberKey = (String) student.get("MEMBER_KEY");
                        String key = courseCode + ":" + memberKey + ":" + week;

                        if (!attendanceRecords.containsKey(key)) {
                            recordAttendance(courseCode, memberKey, week, "ABSENT", "자동 결석 처리");
                            processedCount++;
                        }
                    }
                }
            }
        }

        log.info("만료된 차시 결석 처리 완료: {}건", processedCount);
    }

    /**
     * 교수자 유효기간 수동 조정
     */
    public Map<String, Object> adjustValidity(String courseCode, int week,
                                               String newValidFrom, String newValidTo) {
        // 실제로는 DB 업데이트
        log.info("유효기간 조정: {} week{} -> {} ~ {}", courseCode, week, newValidFrom, newValidTo);

        return Map.of(
            "success", true,
            "courseCode", courseCode,
            "week", week,
            "newValidFrom", newValidFrom,
            "newValidTo", newValidTo,
            "message", "유효기간이 조정되었습니다."
        );
    }

    private String calculateRemainingTime(LocalDateTime now, LocalDateTime endTime) {
        if (now.isAfter(endTime)) return "만료됨";

        long minutes = java.time.Duration.between(now, endTime).toMinutes();
        if (minutes < 60) return minutes + "분 남음";
        if (minutes < 1440) return (minutes / 60) + "시간 " + (minutes % 60) + "분 남음";
        return (minutes / 1440) + "일 남음";
    }

    /**
     * 출석 기록 클래스
     */
    private static class AttendanceRecord {
        String courseCode;
        String memberKey;
        int week;
        String status;
        LocalDateTime timestamp;
        String reason;

        AttendanceRecord(String courseCode, String memberKey, int week,
                        String status, LocalDateTime timestamp, String reason) {
            this.courseCode = courseCode;
            this.memberKey = memberKey;
            this.week = week;
            this.status = status;
            this.timestamp = timestamp;
            this.reason = reason;
        }
    }
}
