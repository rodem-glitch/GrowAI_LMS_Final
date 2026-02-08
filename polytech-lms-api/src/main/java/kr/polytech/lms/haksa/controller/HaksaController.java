// polytech-lms-api/src/main/java/kr/polytech/lms/haksa/controller/HaksaController.java
package kr.polytech.lms.haksa.controller;

import kr.polytech.lms.haksa.service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * 학사 연동 API 컨트롤러
 * RFP 8개 항목 전체 기능 제공
 */
@Slf4j
@RestController
@RequestMapping("/api/haksa")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class HaksaController {

    private final MockDataService mockDataService;
    private final CourseSyncService courseSyncService;
    private final SyllabusService syllabusService;
    private final AntiFraudService antiFraudService;
    private final AttendanceService attendanceService;
    private final GradeService gradeService;

    // MemberSyncService는 poly-sync.enabled=true일 때만 빈 등록됨
    @Autowired(required = false)
    private MemberSyncService memberSyncService;

    // ==================== 강좌/개설정보 API ====================

    /**
     * 전체 강좌 목록 조회
     */
    @GetMapping("/courses")
    public ResponseEntity<Map<String, Object>> getAllCourses() {
        List<Map<String, Object>> courses = mockDataService.getAllCourses();
        return ResponseEntity.ok(Map.of(
            "success", true,
            "data", courses,
            "count", courses.size()
        ));
    }

    /**
     * 강좌 상세 조회
     */
    @GetMapping("/courses/{courseCode}")
    public ResponseEntity<Map<String, Object>> getCourse(@PathVariable String courseCode) {
        return mockDataService.getCourseByCode(courseCode)
            .map(course -> ResponseEntity.ok(Map.of("success", true, "data", course)))
            .orElse(ResponseEntity.notFound().build());
    }

    /**
     * 개설정보 동기화 (학사포털 → LMS)
     */
    @PostMapping("/courses/sync")
    public ResponseEntity<Map<String, Object>> syncCourses() {
        Map<String, Object> result = courseSyncService.syncAllCourses();
        return ResponseEntity.ok(result);
    }

    /**
     * 동기화 상태 조회
     */
    @GetMapping("/courses/sync/status")
    public ResponseEntity<Map<String, Object>> getSyncStatus() {
        Map<String, Object> status = courseSyncService.getSyncStatus();
        return ResponseEntity.ok(status);
    }

    // ==================== 강좌 계획서 API ====================

    /**
     * 강좌 계획서 조회
     */
    @GetMapping("/syllabus/{courseCode}")
    public ResponseEntity<Map<String, Object>> getSyllabus(@PathVariable String courseCode) {
        Map<String, Object> syllabus = syllabusService.getSyllabus(courseCode);
        return ResponseEntity.ok(Map.of("success", true, "data", syllabus));
    }

    /**
     * 강좌 계획서 PDF 생성
     */
    @GetMapping("/syllabus/{courseCode}/pdf")
    public ResponseEntity<Map<String, Object>> getSyllabusPdf(@PathVariable String courseCode) {
        Map<String, Object> pdfInfo = syllabusService.generateSyllabusPdf(courseCode);
        return ResponseEntity.ok(pdfInfo);
    }

    /**
     * 강좌 계획서 가져오기 (학사포털 → LMS)
     */
    @PostMapping("/syllabus/{courseCode}/import")
    public ResponseEntity<Map<String, Object>> importSyllabus(@PathVariable String courseCode) {
        Map<String, Object> result = syllabusService.importFromHaksa(courseCode);
        return ResponseEntity.ok(result);
    }

    // ==================== 출결 관리 API ====================

    /**
     * 차시 유효기간 조회
     */
    @GetMapping("/attendance/validity/{courseCode}/{week}")
    public ResponseEntity<Map<String, Object>> getLessonValidity(
            @PathVariable String courseCode,
            @PathVariable int week) {
        Map<String, Object> validity = attendanceService.getLessonValidity(courseCode, week);
        return ResponseEntity.ok(validity);
    }

    /**
     * 출석 체크
     */
    @PostMapping("/attendance/check")
    public ResponseEntity<Map<String, Object>> checkAttendance(
            @RequestBody Map<String, Object> request) {
        String courseCode = (String) request.get("courseCode");
        String memberKey = (String) request.get("memberKey");
        int week = ((Number) request.get("week")).intValue();

        Map<String, Object> result = attendanceService.checkAttendance(courseCode, memberKey, week);
        return ResponseEntity.ok(result);
    }

    /**
     * 학생 출석 현황 조회
     */
    @GetMapping("/attendance/student/{courseCode}/{memberKey}")
    public ResponseEntity<Map<String, Object>> getStudentAttendance(
            @PathVariable String courseCode,
            @PathVariable String memberKey) {
        Map<String, Object> attendance = attendanceService.getStudentAttendance(courseCode, memberKey);
        return ResponseEntity.ok(attendance);
    }

    /**
     * 강좌별 출석 현황 조회 (교수자용)
     */
    @GetMapping("/attendance/course/{courseCode}")
    public ResponseEntity<Map<String, Object>> getCourseAttendance(@PathVariable String courseCode) {
        Map<String, Object> attendance = attendanceService.getCourseAttendance(courseCode);
        return ResponseEntity.ok(attendance);
    }

    /**
     * 유효기간 조정 (교수자용)
     */
    @PutMapping("/attendance/validity/{courseCode}/{week}")
    public ResponseEntity<Map<String, Object>> adjustValidity(
            @PathVariable String courseCode,
            @PathVariable int week,
            @RequestBody Map<String, String> request) {
        String validFrom = request.get("validFrom");
        String validTo = request.get("validTo");

        Map<String, Object> result = attendanceService.adjustValidity(courseCode, week, validFrom, validTo);
        return ResponseEntity.ok(result);
    }

    // ==================== 대리출석 방지 API ====================

    /**
     * 세션 검증 (로그인 시 호출)
     */
    @PostMapping("/antifraud/validate-session")
    public ResponseEntity<Map<String, Object>> validateSession(
            @RequestBody Map<String, String> request) {
        String memberKey = request.get("memberKey");
        String ipAddress = request.get("ipAddress");
        String userAgent = request.get("userAgent");
        String fingerprint = request.get("fingerprint");

        Map<String, Object> result = antiFraudService.validateSession(
            memberKey, ipAddress, userAgent, fingerprint);
        return ResponseEntity.ok(result);
    }

    /**
     * 학습 행동 패턴 검증
     */
    @PostMapping("/antifraud/validate-behavior")
    public ResponseEntity<Map<String, Object>> validateBehavior(
            @RequestBody Map<String, Object> request) {
        String memberKey = (String) request.get("memberKey");
        String courseCode = (String) request.get("courseCode");
        @SuppressWarnings("unchecked")
        Map<String, Object> behaviorData = (Map<String, Object>) request.get("behaviorData");

        Map<String, Object> result = antiFraudService.validateLearningBehavior(
            memberKey, courseCode, behaviorData);
        return ResponseEntity.ok(result);
    }

    /**
     * 부정행위 로그 조회
     */
    @GetMapping("/antifraud/logs")
    public ResponseEntity<Map<String, Object>> getFraudLogs(
            @RequestParam(defaultValue = "50") int limit) {
        List<Map<String, Object>> logs = antiFraudService.getFraudLogs(limit);
        return ResponseEntity.ok(Map.of(
            "success", true,
            "data", logs,
            "count", logs.size()
        ));
    }

    /**
     * 부정행위 통계
     */
    @GetMapping("/antifraud/statistics")
    public ResponseEntity<Map<String, Object>> getFraudStatistics() {
        Map<String, Object> stats = antiFraudService.getFraudStatistics();
        return ResponseEntity.ok(Map.of("success", true, "data", stats));
    }

    // ==================== 성적 관리 API ====================

    /**
     * 성적 기준 조회
     */
    @GetMapping("/grade/criteria/{courseCode}")
    public ResponseEntity<Map<String, Object>> getGradeCriteria(@PathVariable String courseCode) {
        Map<String, Object> criteria = gradeService.getGradeCriteria(courseCode);
        return ResponseEntity.ok(criteria);
    }

    /**
     * 성적 기준 수정
     */
    @PutMapping("/grade/criteria/{courseCode}")
    public ResponseEntity<Map<String, Object>> updateGradeCriteria(
            @PathVariable String courseCode,
            @RequestBody Map<String, Object> newCriteria) {
        Map<String, Object> result = gradeService.updateGradeCriteria(courseCode, newCriteria);
        return ResponseEntity.ok(result);
    }

    /**
     * 성적 기준 잠금 (학사포털 연동)
     */
    @PostMapping("/grade/criteria/{courseCode}/lock")
    public ResponseEntity<Map<String, Object>> lockGradeCriteria(@PathVariable String courseCode) {
        gradeService.lockGradeCriteria(courseCode);
        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "성적 기준이 잠금 처리되었습니다.",
            "courseCode", courseCode
        ));
    }

    /**
     * 학생 성적 조회
     */
    @GetMapping("/grade/student/{courseCode}/{memberKey}")
    public ResponseEntity<Map<String, Object>> getStudentGrade(
            @PathVariable String courseCode,
            @PathVariable String memberKey) {
        Map<String, Object> grade = gradeService.getStudentGrade(courseCode, memberKey);
        return ResponseEntity.ok(grade);
    }

    /**
     * 성적 등록/수정
     */
    @PostMapping("/grade/register")
    public ResponseEntity<Map<String, Object>> registerGrade(
            @RequestBody Map<String, Object> request) {
        String courseCode = (String) request.get("courseCode");
        String memberKey = (String) request.get("memberKey");
        @SuppressWarnings("unchecked")
        Map<String, Object> scores = (Map<String, Object>) request.get("scores");

        Map<String, Object> result = gradeService.registerGrade(courseCode, memberKey, scores);
        return ResponseEntity.ok(result);
    }

    /**
     * 강좌별 전체 성적 조회 (교수자용)
     */
    @GetMapping("/grade/course/{courseCode}")
    public ResponseEntity<Map<String, Object>> getCourseGrades(@PathVariable String courseCode) {
        Map<String, Object> grades = gradeService.getCourseGrades(courseCode);
        return ResponseEntity.ok(grades);
    }

    /**
     * 학위/비학위 과정 정보 조회
     */
    @GetMapping("/grade/degree/{courseCode}")
    public ResponseEntity<Map<String, Object>> getDegreeInfo(@PathVariable String courseCode) {
        Map<String, Object> degreeInfo = gradeService.getDegreeInfo(courseCode);
        return ResponseEntity.ok(degreeInfo);
    }

    // ==================== 회원 정보 API ====================

    /**
     * 회원 정보 조회
     */
    @GetMapping("/members/{memberKey}")
    public ResponseEntity<Map<String, Object>> getMember(@PathVariable String memberKey) {
        return mockDataService.getMemberByKey(memberKey)
            .map(member -> ResponseEntity.ok(Map.of("success", true, "data", member)))
            .orElse(ResponseEntity.notFound().build());
    }

    /**
     * 강좌별 수강생 목록
     */
    @GetMapping("/courses/{courseCode}/students")
    public ResponseEntity<Map<String, Object>> getStudentsByCourse(@PathVariable String courseCode) {
        List<Map<String, Object>> students = mockDataService.getStudentsByCourse(courseCode);
        return ResponseEntity.ok(Map.of(
            "success", true,
            "data", students,
            "count", students.size()
        ));
    }

    /**
     * 강좌별 교수자 목록
     */
    @GetMapping("/courses/{courseCode}/professors")
    public ResponseEntity<Map<String, Object>> getProfessorsByCourse(@PathVariable String courseCode) {
        List<Map<String, Object>> professors = mockDataService.getProfessorsByCourse(courseCode);
        return ResponseEntity.ok(Map.of(
            "success", true,
            "data", professors,
            "count", professors.size()
        ));
    }

    // ==================== 차시 계획 API ====================

    /**
     * 강좌별 차시 계획 조회
     */
    @GetMapping("/lectplan/{courseCode}")
    public ResponseEntity<Map<String, Object>> getLectPlans(@PathVariable String courseCode) {
        List<Map<String, Object>> plans = mockDataService.getLectPlansByCourse(courseCode);
        return ResponseEntity.ok(Map.of(
            "success", true,
            "data", plans,
            "count", plans.size()
        ));
    }

    /**
     * 특정 차시 계획 조회
     */
    @GetMapping("/lectplan/{courseCode}/{week}")
    public ResponseEntity<Map<String, Object>> getLectPlan(
            @PathVariable String courseCode,
            @PathVariable int week) {
        return mockDataService.getLectPlan(courseCode, week)
            .map(plan -> ResponseEntity.ok(Map.of("success", true, "data", plan)))
            .orElse(ResponseEntity.notFound().build());
    }

    // ==================== 대시보드 API ====================

    /**
     * 학생 대시보드 데이터
     */
    @GetMapping("/dashboard/student/{memberKey}")
    public ResponseEntity<Map<String, Object>> getStudentDashboard(@PathVariable String memberKey) {
        List<Map<String, Object>> enrollments = mockDataService.getEnrollmentsByMember(memberKey);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "memberKey", memberKey,
            "courses", enrollments,
            "courseCount", enrollments.size()
        ));
    }

    /**
     * 교수자 대시보드 데이터
     */
    @GetMapping("/dashboard/professor/{memberKey}")
    public ResponseEntity<Map<String, Object>> getProfessorDashboard(@PathVariable String memberKey) {
        List<Map<String, Object>> courses = mockDataService.getCoursesByProfessor(memberKey);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "memberKey", memberKey,
            "courses", courses,
            "courseCount", courses.size()
        ));
    }

    /**
     * 관리자 대시보드 데이터
     */
    @GetMapping("/dashboard/admin")
    public ResponseEntity<Map<String, Object>> getAdminDashboard() {
        List<Map<String, Object>> courses = mockDataService.getAllCourses();
        Map<String, Object> fraudStats = antiFraudService.getFraudStatistics();
        Map<String, Object> syncStatus = courseSyncService.getSyncStatus();

        return ResponseEntity.ok(Map.of(
            "success", true,
            "totalCourses", courses.size(),
            "syncStatus", syncStatus,
            "fraudStatistics", fraudStats
        ));
    }

    // ==================== 회원 동기화 API (poly_sync) ====================

    /**
     * 회원 동기화 수동 실행 (학사포털 → LMS)
     */
    @PostMapping("/members/sync")
    public ResponseEntity<Map<String, Object>> syncMembers() {
        if (memberSyncService == null) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "회원 동기화 기능이 비활성화 상태입니다. (poly-sync.enabled=true 필요)"));
        }
        Map<String, Object> result = memberSyncService.manualSync();
        return ResponseEntity.ok(result);
    }

    /**
     * 회원 동기화 상태 조회
     */
    @GetMapping("/members/sync/status")
    public ResponseEntity<Map<String, Object>> getMemberSyncStatus() {
        if (memberSyncService == null) {
            return ResponseEntity.ok(Map.of("enabled", false, "lastSyncStatus", "DISABLED"));
        }
        return ResponseEntity.ok(memberSyncService.getSyncStatus());
    }

    /**
     * 회원 동기화 이력 조회
     */
    @GetMapping("/members/sync/history")
    public ResponseEntity<Map<String, Object>> getMemberSyncHistory(
            @RequestParam(defaultValue = "20") int limit) {
        if (memberSyncService == null) {
            return ResponseEntity.ok(Map.of("enabled", false, "data", List.of()));
        }
        List<Map<String, Object>> history = memberSyncService.getSyncHistory(limit);
        return ResponseEntity.ok(Map.of("success", true, "data", history, "count", history.size()));
    }

    // ==================== 헬스체크 API ====================

    /**
     * API 헬스체크
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        return ResponseEntity.ok(Map.of(
            "status", "UP",
            "service", "haksa-api",
            "timestamp", java.time.LocalDateTime.now().toString(),
            "version", "1.0.0"
        ));
    }
}
