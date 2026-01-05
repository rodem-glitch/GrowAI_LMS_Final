package kr.polytech.lms.instructorrecommend.repository;

import org.springframework.stereotype.Repository;

@Repository
public class InstructorRecommendRepository {
    // 왜: 교수자 추천은 "벡터 검색"을 공통 모듈로 처리하고,
    //     이 레포지토리는 필요할 때(필터/후보군/권한 등) DB 조회를 담당하도록 자리만 먼저 마련합니다.
}
