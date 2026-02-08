// polytech-lms-api/src/main/java/kr/polytech/lms/legacy/service/CourseService.java
package kr.polytech.lms.legacy.service;

import kr.polytech.lms.legacy.dto.CourseDto;
import kr.polytech.lms.legacy.entity.Course;
import kr.polytech.lms.legacy.repository.CourseRepository;
import kr.polytech.lms.legacy.repository.LessonRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * 과정 Service
 * 레거시 CourseDao의 비즈니스 로직을 Spring Service로 변환
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CourseService {

    private final CourseRepository courseRepository;
    private final LessonRepository lessonRepository;

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    /**
     * 사이트별 과정 목록 조회
     */
    @Cacheable(value = "courses", key = "#siteId")
    public List<CourseDto> getCourseList(Long siteId) {
        return courseRepository.findBySiteId(siteId).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * 과정 상세 조회
     */
    @Cacheable(value = "course", key = "#id + '-' + #siteId")
    public Optional<CourseDto> getCourse(Long id, Long siteId) {
        return courseRepository.findByIdAndSiteId(id, siteId)
                .map(this::toDto);
    }

    /**
     * 판매 중인 과정 조회
     */
    public List<CourseDto> getActiveSaleCourses(Long siteId) {
        return courseRepository.findActiveSaleCourses(siteId).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * 패키지 과정 조회
     */
    public List<CourseDto> getPackageCourses(Long siteId) {
        return courseRepository.findPackageCourses(siteId).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * 비패키지 과정 조회
     */
    public List<CourseDto> getNonPackageCourses(Long siteId) {
        return courseRepository.findNonPackageCourses(siteId).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * 과정 복사
     */
    @Transactional
    public Long copyCourse(Long courseId, Integer year, Integer step, String courseNm,
                           String requestSdate, String requestEdate,
                           String studySdate, String studyEdate, Integer lessonDay) {
        if (courseId == null || year == null || step == null || courseNm == null || courseNm.isEmpty()) {
            return -1L;
        }

        Optional<Course> originalOpt = courseRepository.findById(courseId);
        if (originalOpt.isEmpty() || "P".equals(originalOpt.get().getOnoffType())) {
            return -1L;
        }

        Course original = originalOpt.get();
        Course newCourse = Course.builder()
                .siteId(original.getSiteId())
                .courseNm(courseNm)
                .courseType(original.getCourseType())
                .onoffType(original.getOnoffType())
                .status(1)
                .displayYn("N")
                .saleYn("N")
                .taxfreeYn(original.getTaxfreeYn())
                .year(year)
                .step(step)
                .closeYn("N")
                .managerId(original.getManagerId())
                .sort(original.getSort())
                .allsort(original.getAllsort())
                .recommYn(original.getRecommYn())
                .regDate(LocalDateTime.now().format(DATE_FORMATTER))
                .build();

        // 과정 유형에 따른 날짜 설정
        if ("R".equals(original.getCourseType())) {
            newCourse.setRequestSdate(requestSdate);
            newCourse.setRequestEdate(requestEdate);
            newCourse.setStudySdate(studySdate);
            newCourse.setStudyEdate(studyEdate);
        } else if ("A".equals(original.getCourseType())) {
            newCourse.setLessonDay(lessonDay);
        }

        Course saved = courseRepository.save(newCourse);
        log.info("과정 복사 완료 - 원본: {}, 신규: {}", courseId, saved.getId());
        return saved.getId();
    }

    /**
     * Entity to DTO 변환
     */
    private CourseDto toDto(Course course) {
        Long lessonCount = lessonRepository.countByCourseId(course.getId());
        Integer totalPlayTime = lessonRepository.getTotalPlayTime(course.getId());

        return CourseDto.builder()
                .id(course.getId())
                .siteId(course.getSiteId())
                .courseNm(course.getCourseNm())
                .courseType(course.getCourseType())
                .courseTypeLabel(course.getCourseTypeEnum().getLabel())
                .onoffType(course.getOnoffType())
                .onoffTypeLabel(course.getOnOffTypeEnum().getLabel())
                .status(course.getStatus())
                .statusLabel(course.getCourseStatusEnum().getLabel())
                .displayYn(course.getDisplayYn())
                .saleYn(course.getSaleYn())
                .year(course.getYear())
                .step(course.getStep())
                .requestSdate(course.getRequestSdate())
                .requestEdate(course.getRequestEdate())
                .studySdate(course.getStudySdate())
                .studyEdate(course.getStudyEdate())
                .lessonDay(course.getLessonDay())
                .lessonCount(lessonCount)
                .totalPlayTime(totalPlayTime)
                .regDate(course.getRegDate())
                .build();
    }
}
