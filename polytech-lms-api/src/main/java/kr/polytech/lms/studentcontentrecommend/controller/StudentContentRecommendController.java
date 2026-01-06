package kr.polytech.lms.studentcontentrecommend.controller;

import java.util.List;
import kr.polytech.lms.studentcontentrecommend.service.StudentContentRecommendService;
import kr.polytech.lms.studentcontentrecommend.service.dto.StudentHomeRecommendRequest;
import kr.polytech.lms.studentcontentrecommend.service.dto.StudentSearchRecommendRequest;
import kr.polytech.lms.studentcontentrecommend.service.dto.StudentVideoRecommendResponse;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/student/content-recommend")
public class StudentContentRecommendController {

    private final StudentContentRecommendService studentContentRecommendService;

    public StudentContentRecommendController(StudentContentRecommendService studentContentRecommendService) {
        // 왜: 학생 추천은 "홈 추천(프로필/수강과목 기반)"과 "검색(자연어)" 두 흐름이어서 전용 컨트롤러로 분리합니다.
        this.studentContentRecommendService = studentContentRecommendService;
    }

    @PostMapping("/home")
    public List<StudentVideoRecommendResponse> recommendHome(@RequestBody(required = false) StudentHomeRecommendRequest request) {
        return studentContentRecommendService.recommendHome(request);
    }

    @PostMapping("/search")
    public List<StudentVideoRecommendResponse> recommendSearch(@RequestBody(required = false) StudentSearchRecommendRequest request) {
        return studentContentRecommendService.recommendSearch(request);
    }
}

