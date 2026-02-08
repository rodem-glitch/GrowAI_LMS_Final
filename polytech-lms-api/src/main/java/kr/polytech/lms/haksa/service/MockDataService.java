// polytech-lms-api/src/main/java/kr/polytech/lms/haksa/service/MockDataService.java
package kr.polytech.lms.haksa.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.util.*;
import java.util.HashMap;
import java.util.stream.Collectors;

/**
 * Mock 데이터 서비스
 * 8종 뷰테이블 162개 컬럼 시뮬레이션
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MockDataService {

    private final ObjectMapper objectMapper;

    // 캐시된 데이터
    private List<Map<String, Object>> courseData = new ArrayList<>();
    private List<Map<String, Object>> lectPlanData = new ArrayList<>();
    private List<Map<String, Object>> lectPlanNcsData = new ArrayList<>();
    private List<Map<String, Object>> memberData = new ArrayList<>();
    private List<Map<String, Object>> studentData = new ArrayList<>();
    private List<Map<String, Object>> professorData = new ArrayList<>();
    private List<Map<String, Object>> courseInfoData = new ArrayList<>();
    private List<Map<String, Object>> jobPostingData = new ArrayList<>();

    @PostConstruct
    public void init() {
        try {
            courseData = loadMockData("mock-data/lms_course_view.json");
            lectPlanData = loadMockData("mock-data/lms_lectplan_view.json");
            lectPlanNcsData = loadMockData("mock-data/lms_lectplan_ncs_view.json");
            memberData = loadMockData("mock-data/lms_member_view.json");
            studentData = loadMockData("mock-data/lms_student_view.json");
            professorData = loadMockData("mock-data/lms_professor_view.json");
            courseInfoData = loadMockData("mock-data/course_info_view.json");
            jobPostingData = loadMockData("mock-data/job_posting_view.json");

            log.info("Mock 데이터 로드 완료: courses={}, lectPlans={}, members={}, students={}, professors={}",
                courseData.size(), lectPlanData.size(), memberData.size(),
                studentData.size(), professorData.size());
        } catch (Exception e) {
            log.error("Mock 데이터 로드 실패: {}", e.getMessage());
        }
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> loadMockData(String path) throws IOException {
        ClassPathResource resource = new ClassPathResource(path);
        Map<String, Object> json = objectMapper.readValue(
            resource.getInputStream(),
            new TypeReference<Map<String, Object>>() {}
        );
        return (List<Map<String, Object>>) json.get("data");
    }

    // ==================== LMS_COURSE_VIEW ====================

    public List<Map<String, Object>> getAllCourses() {
        return new ArrayList<>(courseData);
    }

    public Optional<Map<String, Object>> getCourseByCode(String courseCode) {
        return courseData.stream()
            .filter(c -> courseCode.equals(c.get("COURSE_CODE")))
            .findFirst();
    }

    public List<Map<String, Object>> getCoursesByDept(String deptCode) {
        return courseData.stream()
            .filter(c -> deptCode.equals(c.get("DEPT_CODE")))
            .collect(Collectors.toList());
    }

    public List<Map<String, Object>> getCoursesByProfessor(String professorKey) {
        return courseData.stream()
            .filter(c -> professorKey.equals(c.get("PROFESSOR_KEY")))
            .collect(Collectors.toList());
    }

    // ==================== LMS_LECTPLAN_VIEW ====================

    public List<Map<String, Object>> getLectPlansByCourse(String courseCode) {
        return lectPlanData.stream()
            .filter(l -> courseCode.equals(l.get("COURSE_CODE")))
            .sorted((a, b) -> Integer.compare(
                (Integer) a.get("LSN_WEKORD"),
                (Integer) b.get("LSN_WEKORD")))
            .collect(Collectors.toList());
    }

    public Optional<Map<String, Object>> getLectPlan(String courseCode, int week) {
        return lectPlanData.stream()
            .filter(l -> courseCode.equals(l.get("COURSE_CODE"))
                && week == (Integer) l.get("LSN_WEKORD"))
            .findFirst();
    }

    // ==================== LMS_LECTPLAN_NCS_VIEW ====================

    public List<Map<String, Object>> getNcsDataByCourse(String courseCode) {
        return lectPlanNcsData.stream()
            .filter(n -> courseCode.equals(n.get("COURSE_CODE")))
            .collect(Collectors.toList());
    }

    // ==================== LMS_MEMBER_VIEW ====================

    public Optional<Map<String, Object>> getMemberByKey(String memberKey) {
        return memberData.stream()
            .filter(m -> memberKey.equals(m.get("MEMBER_KEY")))
            .findFirst();
    }

    public Optional<Map<String, Object>> getMemberByUserId(String userId) {
        return memberData.stream()
            .filter(m -> userId.equals(m.get("USER_ID")))
            .findFirst();
    }

    public List<Map<String, Object>> getMembersByType(String userType) {
        return memberData.stream()
            .filter(m -> userType.equals(m.get("USER_TYPE")))
            .collect(Collectors.toList());
    }

    public List<Map<String, Object>> getMembersByCampus(String campusCode) {
        return memberData.stream()
            .filter(m -> campusCode.equals(m.get("CAMPUS_CODE")))
            .collect(Collectors.toList());
    }

    // ==================== LMS_STUDENT_VIEW ====================

    public List<Map<String, Object>> getStudentsByCourse(String courseCode) {
        return studentData.stream()
            .filter(s -> courseCode.equals(s.get("COURSE_CODE")))
            .collect(Collectors.toList());
    }

    public List<Map<String, Object>> getCoursesByStudent(String memberKey) {
        return studentData.stream()
            .filter(s -> memberKey.equals(s.get("MEMBER_KEY")))
            .collect(Collectors.toList());
    }

    public List<Map<String, Object>> getEnrollmentsByMember(String memberKey) {
        // 학생의 수강 정보 + 강좌 정보 조합
        return studentData.stream()
            .filter(s -> memberKey.equals(s.get("MEMBER_KEY")))
            .map(enrollment -> {
                String courseCode = (String) enrollment.get("COURSE_CODE");
                Optional<Map<String, Object>> courseOpt = getCourseByCode(courseCode);

                Map<String, Object> result = new HashMap<>(enrollment);
                courseOpt.ifPresent(course -> {
                    result.put("COURSE_NAME", course.get("COURSE_NAME"));
                    result.put("DEPT_NAME", course.get("DEPT_NAME"));
                    result.put("PROFESSOR_NAME", course.get("PROFESSOR_NAME"));
                    result.put("STARTDATE", course.get("STARTDATE"));
                    result.put("ENDDATE", course.get("ENDDATE"));
                });
                return result;
            })
            .collect(Collectors.toList());
    }

    // ==================== LMS_PROFESSOR_VIEW ====================

    public List<Map<String, Object>> getProfessorsByCourse(String courseCode) {
        return professorData.stream()
            .filter(p -> courseCode.equals(p.get("COURSE_CODE")))
            .sorted((a, b) -> Integer.compare(
                (Integer) a.get("PROF_ORDER"),
                (Integer) b.get("PROF_ORDER")))
            .collect(Collectors.toList());
    }

    public List<Map<String, Object>> getCoursesByProfessorKey(String memberKey) {
        return professorData.stream()
            .filter(p -> memberKey.equals(p.get("MEMBER_KEY")))
            .collect(Collectors.toList());
    }

    // ==================== COURSE_INFO_VIEW ====================

    public List<Map<String, Object>> getAllCurriculums() {
        return new ArrayList<>(courseInfoData);
    }

    public Optional<Map<String, Object>> getCurriculumByCode(String curriculumCode) {
        return courseInfoData.stream()
            .filter(c -> curriculumCode.equals(c.get("CURRICULUM_CODE")))
            .findFirst();
    }

    // ==================== 채용공고_VIEW ====================

    public List<Map<String, Object>> getAllJobPostings() {
        return new ArrayList<>(jobPostingData);
    }

    public List<Map<String, Object>> getJobPostingsByDept(String deptCode) {
        return jobPostingData.stream()
            .filter(j -> {
                String relatedDept = (String) j.get("RELATED_DEPT");
                return relatedDept != null && relatedDept.contains(deptCode);
            })
            .collect(Collectors.toList());
    }

    // ==================== 통계 ====================

    public Map<String, Object> getStatistics() {
        return Map.of(
            "totalCourses", courseData.size(),
            "totalMembers", memberData.size(),
            "totalStudents", memberData.stream()
                .filter(m -> "10".equals(m.get("USER_TYPE"))).count(),
            "totalProfessors", memberData.stream()
                .filter(m -> "30".equals(m.get("USER_TYPE"))).count(),
            "totalJobPostings", jobPostingData.size(),
            "totalCurriculums", courseInfoData.size()
        );
    }
}
