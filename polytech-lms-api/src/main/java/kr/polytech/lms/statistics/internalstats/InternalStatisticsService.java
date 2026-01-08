package kr.polytech.lms.statistics.internalstats;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Objects;

import kr.polytech.lms.statistics.util.StatisticsFileLocator;

@Service
public class InternalStatisticsService {
    // 왜: 내부(입학/취업) 통계는 실제 운영에서는 DB 적재가 정석이지만,
    //     초기 고도화 단계에서는 "통계 폴더의 엑셀"을 그대로 읽어 빠르게 화면을 구현할 수 있습니다.

    private final StatisticsDataProperties properties;
    private final DataFormatter formatter;

    private volatile List<EmploymentRow> cachedEmploymentRows;
    private final Object employmentLock = new Object();

    private volatile List<AdmissionRow> cachedAdmissionRows;
    private final Object admissionLock = new Object();

    public InternalStatisticsService(StatisticsDataProperties properties) {
        this.properties = properties;
        this.formatter = new DataFormatter(Locale.KOREA);
    }

    public List<DepartmentRate> getEmploymentRates(String campus) {
        String resolvedCampus = requireCampus(campus);

        return getOrLoadEmploymentRows().stream()
                .filter(r -> resolvedCampus.equals(r.campus()))
                .map(r -> new DepartmentRate(r.dept(), r.employmentRate()))
                .sorted(Comparator.comparingDouble(DepartmentRate::rate).reversed())
                .toList();
    }

    public List<DepartmentRate> getTopEmploymentRates(String campus, int top) {
        return getEmploymentRates(campus).stream()
                .limit(Math.max(1, top))
                .toList();
    }

    public List<DepartmentRate> getAdmissionFillRates(String campus) {
        String resolvedCampus = requireCampus(campus);

        return getOrLoadAdmissionRows().stream()
                .filter(r -> resolvedCampus.equals(r.campus()))
                .map(r -> new DepartmentRate(r.dept(), r.fillRate()))
                .sorted(Comparator.comparingDouble(DepartmentRate::rate).reversed())
                .toList();
    }

    public List<DepartmentRate> getTopAdmissionFillRates(String campus, int top) {
        return getAdmissionFillRates(campus).stream()
                .limit(Math.max(1, top))
                .toList();
    }

    private List<EmploymentRow> getOrLoadEmploymentRows() {
        List<EmploymentRow> existing = cachedEmploymentRows;
        if (existing != null) {
            return existing;
        }

        synchronized (employmentLock) {
            if (cachedEmploymentRows != null) {
                return cachedEmploymentRows;
            }
            cachedEmploymentRows = loadEmploymentRowsFromExcel();
            return cachedEmploymentRows;
        }
    }

    private List<AdmissionRow> getOrLoadAdmissionRows() {
        List<AdmissionRow> existing = cachedAdmissionRows;
        if (existing != null) {
            return existing;
        }

        synchronized (admissionLock) {
            if (cachedAdmissionRows != null) {
                return cachedAdmissionRows;
            }
            cachedAdmissionRows = loadAdmissionRowsFromExcel();
            return cachedAdmissionRows;
        }
    }

    private List<EmploymentRow> loadEmploymentRowsFromExcel() {
        Path path = resolveFilePath(properties.getEmploymentFile(), "statistics.data.employment-file");

        try (InputStream in = Files.newInputStream(path); Workbook workbook = WorkbookFactory.create(in)) {
            Sheet sheet = Objects.requireNonNullElse(workbook.getSheet("학과별취업현황(종합)"), workbook.getSheetAt(0));

            List<EmploymentRow> rows = new ArrayList<>();
            for (Row row : sheet) {
                // 왜: 상단 제목/헤더 영역을 건너뛰고, 실제 데이터 행만 처리합니다.
                if (row.getRowNum() < 8) {
                    continue;
                }

                String campus = getCellString(row, 1);
                String dept = getCellString(row, 3);

                Double employed = getCellNumber(row, 13);
                Double employTarget = getCellNumber(row, 12);

                if (!StringUtils.hasText(campus) || !StringUtils.hasText(dept)) {
                    continue;
                }
                if (isSummaryDept(dept)) {
                    continue;
                }
                if (employed == null || employTarget == null || employTarget <= 0) {
                    continue;
                }

                double rate = (employed / employTarget) * 100.0;
                rows.add(new EmploymentRow(normalizeCampus(campus), dept.trim(), rate));
            }

            return rows;
        } catch (Exception e) {
            throw new IllegalStateException("취업 통계 엑셀을 읽지 못했습니다. statistics.data.employment-file 경로를 확인해 주세요.", e);
        }
    }

    private List<AdmissionRow> loadAdmissionRowsFromExcel() {
        Path path = resolveFilePath(properties.getAdmissionFile(), "statistics.data.admission-file");

        try (InputStream in = Files.newInputStream(path); Workbook workbook = WorkbookFactory.create(in)) {
            Sheet sheet = workbook.getSheetAt(0);
            if (workbook.getSheet("2025.11.25. 24시") != null) {
                // 왜: 현재 파일은 '2025.11.25. 24시' 시트에 학과별 정원/모집인원 정보가 들어 있습니다.
                sheet = workbook.getSheet("2025.11.25. 24시");
            }

            List<AdmissionRow> rows = new ArrayList<>();
            for (Row row : sheet) {
                if (row.getRowNum() < 8) {
                    continue;
                }

                String campus = getCellString(row, 1);
                String dept = getCellString(row, 3);

                Double quota = getCellNumber(row, 5);
                Double recruit = getCellNumber(row, 7);

                // 왜: '입시율관리.xlsx'는 파일 버전에 따라 "지원현황/등록현황" 컬럼이 뒤쪽에 추가되어 있습니다.
                //     (예: 2025.11.25. 24시 시트 기준)
                //     - 지원현황 합계(65열)
                //     - 등록현황 합계(71열)
                //     화면의 "입학충원률"은 정식으로는 등록현황 기반이 맞지만,
                //     등록이 아직 집계되지 않은 시점에는 지원현황으로라도 "충원 가능성"을 비교할 수 있게 합니다.
                Double applicants = getCellNumber(row, 64);  // 65열(1-based) = 64(0-based)
                Double registered = getCellNumber(row, 70);  // 71열(1-based) = 70(0-based)
                AdmissionBasis basis = resolveAdmissionBasis(registered, applicants, recruit);
                Double usedCount = resolveAdmissionUsedCount(basis, registered, applicants, recruit);

                if (!StringUtils.hasText(campus) || !StringUtils.hasText(dept)) {
                    continue;
                }
                if (isSummaryDept(dept)) {
                    continue;
                }
                if (quota == null || quota <= 0 || usedCount == null) {
                    continue;
                }

                double rate = (usedCount / quota) * 100.0;
                if (basis != AdmissionBasis.REGISTERED) {
                    // 왜: 지원(접수) 기반 비율은 100%를 초과할 수 있으므로,
                    //     "충원률" 용어와 혼동되지 않도록 100으로 상한을 둡니다.
                    rate = Math.min(rate, 100.0);
                }
                rows.add(new AdmissionRow(normalizeCampus(campus), dept.trim(), rate));
            }

            return rows;
        } catch (Exception e) {
            throw new IllegalStateException("입시 통계 엑셀을 읽지 못했습니다. statistics.data.admission-file 경로를 확인해 주세요.", e);
        }
    }

    private Path resolveFilePath(String filePath, String configKeyName) {
        if (!StringUtils.hasText(filePath)) {
            throw new IllegalStateException("통계 파일 설정이 없습니다. " + configKeyName + " 을 설정해 주세요.");
        }

        Path configured = Path.of(filePath);
        return StatisticsFileLocator.tryResolve(filePath)
                .orElseThrow(() -> new IllegalStateException(
                        "통계 파일을 찾을 수 없습니다. 경로=" + configured + " (현재작업폴더=" + Path.of("").toAbsolutePath() + ")"
                ));
    }

    private String requireCampus(String campus) {
        String resolvedCampus = normalizeCampus(campus);
        if (!StringUtils.hasText(resolvedCampus)) {
            throw new IllegalArgumentException("campus는 필수입니다.");
        }
        return resolvedCampus;
    }

    private String normalizeCampus(String campus) {
        String v = campus == null ? "" : campus.trim();
        if (v.endsWith("캠퍼스")) {
            return v.substring(0, v.length() - "캠퍼스".length()).trim();
        }
        return v;
    }

    private AdmissionBasis resolveAdmissionBasis(Double registered, Double applicants, Double recruit) {
        if (registered != null && registered > 0) {
            return AdmissionBasis.REGISTERED;
        }
        if (applicants != null && applicants >= 0) {
            return AdmissionBasis.APPLICANTS;
        }
        if (recruit != null && recruit >= 0) {
            return AdmissionBasis.RECRUIT;
        }
        return AdmissionBasis.UNKNOWN;
    }

    private Double resolveAdmissionUsedCount(AdmissionBasis basis, Double registered, Double applicants, Double recruit) {
        return switch (basis) {
            case REGISTERED -> registered;
            case APPLICANTS -> applicants;
            case RECRUIT -> recruit;
            case UNKNOWN -> null;
        };
    }

    private boolean isSummaryDept(String dept) {
        String v = dept.trim();
        return v.equals("소계") || v.equals("총계") || v.endsWith("소계") || v.contains("별 소계");
    }

    private String getCellString(Row row, int cellIndexZeroBased) {
        Cell cell = row.getCell(cellIndexZeroBased);
        if (cell == null) {
            return null;
        }
        String value = formatter.formatCellValue(cell);
        return StringUtils.hasText(value) ? value.trim() : null;
    }

    private Double getCellNumber(Row row, int cellIndexZeroBased) {
        String value = getCellString(row, cellIndexZeroBased);
        if (!StringUtils.hasText(value)) {
            return null;
        }

        String normalized = value.replace(",", "");
        try {
            return Double.parseDouble(normalized);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private record EmploymentRow(String campus, String dept, double employmentRate) {
    }

    private record AdmissionRow(String campus, String dept, double fillRate) {
    }

    public record DepartmentRate(String dept, double rate) {
    }

    private enum AdmissionBasis {
        REGISTERED,
        APPLICANTS,
        RECRUIT,
        UNKNOWN
    }
}
