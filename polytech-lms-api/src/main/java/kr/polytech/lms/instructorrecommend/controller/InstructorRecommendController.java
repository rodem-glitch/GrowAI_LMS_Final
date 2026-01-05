package kr.polytech.lms.instructorrecommend.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/instructor-recommend")
public class InstructorRecommendController {
    // 왜: 교수자 추천 AI 기능을 분리해 병렬 개발이 가능하도록 합니다.
}
