package kr.polytech.lms.studentrecommend.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/student-recommend")
public class StudentRecommendController {
    // 왜: 학생 추천 기능도 교수자 추천과 같은 벡터 추천 엔진을 재사용할 예정이라 패키지를 분리해 둡니다.
}
