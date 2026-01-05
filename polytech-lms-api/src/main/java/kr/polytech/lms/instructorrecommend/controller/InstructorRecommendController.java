package kr.polytech.lms.instructorrecommend.controller;

import java.util.List;
import kr.polytech.lms.instructorrecommend.service.InstructorRecommendService;
import kr.polytech.lms.instructorrecommend.service.dto.InstructorVideoRecommendRequest;
import kr.polytech.lms.instructorrecommend.service.dto.InstructorVideoRecommendResponse;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestBody;

@RestController
@RequestMapping("/instructor-recommend")
public class InstructorRecommendController {
    // 왜: 교수자 추천 AI 기능을 분리해 병렬 개발이 가능하도록 합니다.

    private final InstructorRecommendService instructorRecommendService;

    public InstructorRecommendController(InstructorRecommendService instructorRecommendService) {
        this.instructorRecommendService = instructorRecommendService;
    }

    @PostMapping("/videos")
    public List<InstructorVideoRecommendResponse> recommendVideos(@RequestBody InstructorVideoRecommendRequest request) {
        return instructorRecommendService.recommendVideos(request);
    }
}
