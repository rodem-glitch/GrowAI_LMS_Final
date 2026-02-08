// polytech-lms-api/src/main/java/kr/polytech/lms/haksa/service/GradeService.java
package kr.polytech.lms.haksa.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 성적 관리 서비스
 * RFP 항목 #5, #7, #8: 성적 등록, 성적 기준 수정 불가, 학위/비학위 DB 일관성
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GradeService {

    private final MockDataService mockDataService;

    // 성적 기준 저장소 (courseCode -> GradeCriteria)
    private final Map<String, GradeCriteria> gradeCriteria = new ConcurrentHashMap<>();

    // 성적 저장소 (courseCode:memberKey -> GradeRecord)
    private final Map<String, GradeRecord> gradeRecords = new ConcurrentHashMap<>();

    // 기준 잠금 상태 (courseCode -> locked)
    private final Map<String, Boolean> criteriaLocked = new ConcurrentHashMap<>();

    /**
     * 성적 기준 조회
     */
    public Map<String, Object> getGradeCriteria(String courseCode) {
        Optional<Map<String, Object>> courseOpt = mockDataService.getCourseByCode(courseCode);

        if (courseOpt.isEmpty()) {
            throw new IllegalArgumentException("강좌를 찾을 수 없습니다: " + courseCode);
        }

        Map<String, Object> course = courseOpt.get();
        GradeCriteria criteria = gradeCriteria.computeIfAbsent(courseCode,
            k -> createDefaultCriteria(course));

        boolean isLocked = criteriaLocked.getOrDefault(courseCode, false);

        return Map.of(
            "courseCode", courseCode,
            "courseName", course.get("COURSE_NAME"),
            "groupCode", course.getOrDefault("GROUP_CODE", "U"),
            "groupName", "U".equals(course.get("GROUP_CODE")) ? "학부" : "대학원",
            "criteria", criteria.toMap(),
            "isLocked", isLocked,
            "lockedReason", isLocked ? "학사포털에서 성적 기준이 확정되었습니다." : null
        );
    }

    /**
     * 성적 기준 수정 (잠금 상태 확인)
     */
    public Map<String, Object> updateGradeCriteria(String courseCode, Map<String, Object> newCriteria) {
        if (criteriaLocked.getOrDefault(courseCode, false)) {
            return Map.of(
                "success", false,
                "reason", "성적 기준이 잠겨있어 수정할 수 없습니다."
            );
        }

        GradeCriteria criteria = gradeCriteria.get(courseCode);
        if (criteria == null) {
            return Map.of("success", false, "reason", "성적 기준이 없습니다.");
        }

        // 기준 업데이트
        if (newCriteria.containsKey("attendance")) {
            criteria.attendanceRatio = ((Number) newCriteria.get("attendance")).intValue();
        }
        if (newCriteria.containsKey("midterm")) {
            criteria.midtermRatio = ((Number) newCriteria.get("midterm")).intValue();
        }
        if (newCriteria.containsKey("finalExam")) {
            criteria.finalExamRatio = ((Number) newCriteria.get("finalExam")).intValue();
        }
        if (newCriteria.containsKey("assignment")) {
            criteria.assignmentRatio = ((Number) newCriteria.get("assignment")).intValue();
        }

        // 비율 합계 검증
        int total = criteria.attendanceRatio + criteria.midtermRatio +
                   criteria.finalExamRatio + criteria.assignmentRatio;
        if (total != 100) {
            return Map.of("success", false, "reason", "성적 비율 합계가 100%가 아닙니다: " + total + "%");
        }

        // 변경 이력 기록
        logCriteriaChange(courseCode, newCriteria);

        return Map.of(
            "success", true,
            "criteria", criteria.toMap()
        );
    }

    /**
     * 성적 기준 잠금 (학사포털 연동 시 호출)
     */
    public void lockGradeCriteria(String courseCode) {
        criteriaLocked.put(courseCode, true);
        log.info("성적 기준 잠금: {}", courseCode);
    }

    /**
     * 학생 성적 조회
     */
    public Map<String, Object> getStudentGrade(String courseCode, String memberKey) {
        String key = courseCode + ":" + memberKey;
        GradeRecord record = gradeRecords.get(key);

        if (record == null) {
            return Map.of(
                "courseCode", courseCode,
                "memberKey", memberKey,
                "hasGrade", false
            );
        }

        GradeCriteria criteria = gradeCriteria.get(courseCode);
        int totalScore = calculateTotalScore(record, criteria);
        String grade = calculateGrade(totalScore);

        return Map.of(
            "courseCode", courseCode,
            "memberKey", memberKey,
            "hasGrade", true,
            "scores", Map.of(
                "attendance", record.attendanceScore,
                "midterm", record.midtermScore,
                "finalExam", record.finalExamScore,
                "assignment", record.assignmentScore
            ),
            "totalScore", totalScore,
            "grade", grade,
            "gradePoint", getGradePoint(grade)
        );
    }

    /**
     * 성적 등록/수정
     */
    public Map<String, Object> registerGrade(String courseCode, String memberKey,
                                              Map<String, Object> scores) {
        String key = courseCode + ":" + memberKey;

        GradeRecord record = gradeRecords.computeIfAbsent(key,
            k -> new GradeRecord(courseCode, memberKey));

        if (scores.containsKey("attendance")) {
            record.attendanceScore = ((Number) scores.get("attendance")).intValue();
        }
        if (scores.containsKey("midterm")) {
            record.midtermScore = ((Number) scores.get("midterm")).intValue();
        }
        if (scores.containsKey("finalExam")) {
            record.finalExamScore = ((Number) scores.get("finalExam")).intValue();
        }
        if (scores.containsKey("assignment")) {
            record.assignmentScore = ((Number) scores.get("assignment")).intValue();
        }

        record.lastModified = LocalDateTime.now();

        return getStudentGrade(courseCode, memberKey);
    }

    /**
     * 강좌별 전체 성적 조회
     */
    public Map<String, Object> getCourseGrades(String courseCode) {
        List<Map<String, Object>> students = mockDataService.getStudentsByCourse(courseCode);
        List<Map<String, Object>> grades = new ArrayList<>();

        double totalScore = 0;
        int gradeCount = 0;

        for (Map<String, Object> student : students) {
            String memberKey = (String) student.get("MEMBER_KEY");
            Map<String, Object> grade = getStudentGrade(courseCode, memberKey);

            if ((Boolean) grade.get("hasGrade")) {
                Optional<Map<String, Object>> memberOpt = mockDataService.getMemberByKey(memberKey);
                memberOpt.ifPresent(member -> {
                    grade.put("studentNo", student.get("STUDENT_NO"));
                    grade.put("name", member.get("KOR_NAME"));
                    grade.put("className", student.get("BUNBAN_CODE"));
                });

                totalScore += (Integer) grade.get("totalScore");
                gradeCount++;
            }

            grades.add(grade);
        }

        return Map.of(
            "courseCode", courseCode,
            "grades", grades,
            "statistics", Map.of(
                "totalStudents", students.size(),
                "gradedStudents", gradeCount,
                "averageScore", gradeCount > 0 ? Math.round(totalScore / gradeCount * 10) / 10.0 : 0
            )
        );
    }

    /**
     * 학위/비학위 과정 구분 조회
     */
    public Map<String, Object> getDegreeInfo(String courseCode) {
        Optional<Map<String, Object>> courseOpt = mockDataService.getCourseByCode(courseCode);

        if (courseOpt.isEmpty()) {
            throw new IllegalArgumentException("강좌를 찾을 수 없습니다: " + courseCode);
        }

        Map<String, Object> course = courseOpt.get();
        String groupCode = (String) course.getOrDefault("GROUP_CODE", "U");

        return Map.of(
            "courseCode", courseCode,
            "groupCode", groupCode,
            "isDegree", "U".equals(groupCode) || "G".equals(groupCode),
            "groupName", switch (groupCode) {
                case "U" -> "학부 (학위과정)";
                case "G" -> "대학원 (학위과정)";
                default -> "비학위과정";
            },
            "gradePolicy", switch (groupCode) {
                case "U" -> "상대평가 (A: 30%, B: 40%, C: 30%)";
                case "G" -> "절대평가 (B학점 이상 필수)";
                default -> "절대평가 (Pass/Fail)";
            }
        );
    }

    /**
     * 기본 성적 기준 생성
     */
    private GradeCriteria createDefaultCriteria(Map<String, Object> course) {
        String groupCode = (String) course.getOrDefault("GROUP_CODE", "U");

        // 학위/비학위에 따른 기본 기준
        if ("U".equals(groupCode)) {
            return new GradeCriteria(10, 30, 40, 20); // 학부
        } else if ("G".equals(groupCode)) {
            return new GradeCriteria(10, 25, 45, 20); // 대학원
        } else {
            return new GradeCriteria(20, 20, 40, 20); // 비학위
        }
    }

    private int calculateTotalScore(GradeRecord record, GradeCriteria criteria) {
        if (criteria == null) return 0;

        return (record.attendanceScore * criteria.attendanceRatio / 100) +
               (record.midtermScore * criteria.midtermRatio / 100) +
               (record.finalExamScore * criteria.finalExamRatio / 100) +
               (record.assignmentScore * criteria.assignmentRatio / 100);
    }

    private String calculateGrade(int score) {
        if (score >= 95) return "A+";
        if (score >= 90) return "A";
        if (score >= 85) return "B+";
        if (score >= 80) return "B";
        if (score >= 75) return "C+";
        if (score >= 70) return "C";
        if (score >= 65) return "D+";
        if (score >= 60) return "D";
        return "F";
    }

    private double getGradePoint(String grade) {
        return switch (grade) {
            case "A+" -> 4.5;
            case "A" -> 4.0;
            case "B+" -> 3.5;
            case "B" -> 3.0;
            case "C+" -> 2.5;
            case "C" -> 2.0;
            case "D+" -> 1.5;
            case "D" -> 1.0;
            default -> 0.0;
        };
    }

    private void logCriteriaChange(String courseCode, Map<String, Object> newCriteria) {
        log.info("성적 기준 변경: {} - {}", courseCode, newCriteria);
    }

    /**
     * 성적 기준 클래스
     */
    private static class GradeCriteria {
        int attendanceRatio;
        int midtermRatio;
        int finalExamRatio;
        int assignmentRatio;

        GradeCriteria(int attendance, int midterm, int finalExam, int assignment) {
            this.attendanceRatio = attendance;
            this.midtermRatio = midterm;
            this.finalExamRatio = finalExam;
            this.assignmentRatio = assignment;
        }

        Map<String, Object> toMap() {
            return Map.of(
                "attendance", attendanceRatio,
                "midterm", midtermRatio,
                "finalExam", finalExamRatio,
                "assignment", assignmentRatio
            );
        }
    }

    /**
     * 성적 기록 클래스
     */
    private static class GradeRecord {
        String courseCode;
        String memberKey;
        int attendanceScore = 0;
        int midtermScore = 0;
        int finalExamScore = 0;
        int assignmentScore = 0;
        LocalDateTime lastModified;

        GradeRecord(String courseCode, String memberKey) {
            this.courseCode = courseCode;
            this.memberKey = memberKey;
            this.lastModified = LocalDateTime.now();
        }
    }
}
