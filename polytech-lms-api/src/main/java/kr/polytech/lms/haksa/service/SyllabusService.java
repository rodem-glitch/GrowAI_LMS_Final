// polytech-lms-api/src/main/java/kr/polytech/lms/haksa/service/SyllabusService.java
package kr.polytech.lms.haksa.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * 강좌 계획서 서비스
 * RFP 항목 #2: 강좌 계획서 불러오기
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SyllabusService {

    private final MockDataService mockDataService;

    /**
     * 강좌 계획서 조회
     */
    public Map<String, Object> getSyllabus(String courseCode) {
        Optional<Map<String, Object>> courseOpt = mockDataService.getCourseByCode(courseCode);

        if (courseOpt.isEmpty()) {
            throw new IllegalArgumentException("강좌를 찾을 수 없습니다: " + courseCode);
        }

        Map<String, Object> course = courseOpt.get();
        String isSyllabus = (String) course.get("IS_SYLLABUS");

        if (!"Y".equals(isSyllabus)) {
            return Map.of(
                "courseCode", courseCode,
                "hasSyllabus", false,
                "message", "강의계획서가 등록되지 않은 강좌입니다."
            );
        }

        // 주차별 계획 조회
        List<Map<String, Object>> weeklyPlans = mockDataService.getLectPlansByCourse(courseCode);

        // NCS 정보 조회 (TYPE_SYLLABUS = 2인 경우)
        String typeSyllabus = (String) course.get("TYPE_SYLLABUS");
        List<Map<String, Object>> ncsData = "2".equals(typeSyllabus) ?
            mockDataService.getNcsDataByCourse(courseCode) : Collections.emptyList();

        // 교수 정보 조회
        List<Map<String, Object>> professors = mockDataService.getProfessorsByCourse(courseCode);

        // 교과과정 정보 조회
        String curriculumCode = (String) course.get("CURRICULUM_CODE");
        Optional<Map<String, Object>> curriculum = mockDataService.getCurriculumByCode(curriculumCode);

        return Map.of(
            "courseCode", courseCode,
            "hasSyllabus", true,
            "courseInfo", buildCourseInfo(course),
            "professors", professors,
            "weeklyPlans", weeklyPlans,
            "ncsInfo", ncsData,
            "curriculum", curriculum.orElse(Collections.emptyMap()),
            "syllabusType", "2".equals(typeSyllabus) ? "NCS" : "일반"
        );
    }

    /**
     * 강좌 기본 정보 구성
     */
    private Map<String, Object> buildCourseInfo(Map<String, Object> course) {
        return Map.of(
            "courseName", course.getOrDefault("COURSE_NAME", ""),
            "deptName", course.getOrDefault("DEPT_NAME", ""),
            "credit", course.getOrDefault("CREDIT", 0),
            "theoryHours", course.getOrDefault("THEORY_HOURS", 0),
            "practiceHours", course.getOrDefault("PRACTICE_HOURS", 0),
            "totalHours", course.getOrDefault("TOTAL_HOURS", 0),
            "grade", course.getOrDefault("GRADE", ""),
            "category", course.getOrDefault("CATEGORY", ""),
            "startDate", course.getOrDefault("STARTDATE", ""),
            "endDate", course.getOrDefault("ENDDATE", "")
        );
    }

    /**
     * 강의계획서 PDF 데이터 생성
     */
    public Map<String, Object> generateSyllabusPdf(String courseCode) {
        Map<String, Object> syllabus = getSyllabus(courseCode);

        if (!(Boolean) syllabus.get("hasSyllabus")) {
            throw new IllegalArgumentException("강의계획서가 없는 강좌입니다.");
        }

        // PDF 생성 로직 (실제로는 iText 등 사용)
        String pdfUrl = "/api/haksa/syllabus/" + courseCode + "/download";

        return Map.of(
            "courseCode", courseCode,
            "pdfUrl", pdfUrl,
            "generatedAt", System.currentTimeMillis(),
            "syllabus", syllabus
        );
    }

    /**
     * 주차별 강의 내용 조회
     */
    public List<Map<String, Object>> getWeeklyPlans(String courseCode) {
        return mockDataService.getLectPlansByCourse(courseCode);
    }

    /**
     * 특정 주차 강의 내용 조회
     */
    public Optional<Map<String, Object>> getWeekPlan(String courseCode, int week) {
        return mockDataService.getLectPlan(courseCode, week);
    }

    /**
     * 학사포털에서 강의계획서 가져오기
     */
    public Map<String, Object> importFromHaksa(String courseCode) {
        log.info("학사포털에서 강의계획서 가져오기: {}", courseCode);

        Optional<Map<String, Object>> courseOpt = mockDataService.getCourseByCode(courseCode);
        if (courseOpt.isEmpty()) {
            return Map.of(
                "success", false,
                "reason", "강좌를 찾을 수 없습니다: " + courseCode
            );
        }

        // 실제로는 학사포털 API 호출하여 데이터 동기화
        // Mock: 현재 데이터 반환
        Map<String, Object> syllabus = getSyllabus(courseCode);

        return Map.of(
            "success", true,
            "courseCode", courseCode,
            "message", "강의계획서를 성공적으로 가져왔습니다.",
            "importedAt", System.currentTimeMillis(),
            "syllabus", syllabus
        );
    }

    /**
     * 강의계획서 통계
     */
    public Map<String, Object> getSyllabusStatistics() {
        List<Map<String, Object>> courses = mockDataService.getAllCourses();

        long totalCourses = courses.size();
        long withSyllabus = courses.stream()
            .filter(c -> "Y".equals(c.get("IS_SYLLABUS")))
            .count();
        long ncsSyllabus = courses.stream()
            .filter(c -> "Y".equals(c.get("IS_SYLLABUS")) && "2".equals(c.get("TYPE_SYLLABUS")))
            .count();
        long generalSyllabus = withSyllabus - ncsSyllabus;

        return Map.of(
            "totalCourses", totalCourses,
            "withSyllabus", withSyllabus,
            "withoutSyllabus", totalCourses - withSyllabus,
            "ncsSyllabus", ncsSyllabus,
            "generalSyllabus", generalSyllabus,
            "completionRate", totalCourses > 0 ? (double) withSyllabus / totalCourses * 100 : 0
        );
    }
}
