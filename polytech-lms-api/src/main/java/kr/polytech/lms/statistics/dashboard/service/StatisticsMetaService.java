package kr.polytech.lms.statistics.dashboard.service;

import kr.polytech.lms.statistics.mapping.MajorIndustryMappingService;
import kr.polytech.lms.statistics.student.persistence.StudentStatisticsJdbcRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class StatisticsMetaService {
    // 왜: 통계 화면의 드롭다운(캠퍼스/학기 등)은 화면 하드코딩 대신 API로 내려주면 유지보수가 쉬워집니다.

    private final MajorIndustryMappingService majorIndustryMappingService;
    private final StudentStatisticsJdbcRepository studentStatisticsJdbcRepository;

    public StatisticsMetaService(
            MajorIndustryMappingService majorIndustryMappingService,
            StudentStatisticsJdbcRepository studentStatisticsJdbcRepository
    ) {
        this.majorIndustryMappingService = majorIndustryMappingService;
        this.studentStatisticsJdbcRepository = studentStatisticsJdbcRepository;
    }

    public List<MajorIndustryMappingService.CampusGroup> getCampusGroups() {
        return majorIndustryMappingService.getCampusGroups();
    }

    public List<StudentStatisticsJdbcRepository.YearTerm> getRecentYearTerms(int limit) {
        return studentStatisticsJdbcRepository.findRecentYearTerms(limit);
    }
}

