import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Search, Users, Settings } from 'lucide-react';
import { CourseManagement, type CourseManagementTabId } from './CourseManagement';
import { tutorLmsApi } from '../api/tutorLmsApi';

interface Course {
  id: string;
  mappedCourseId?: number;
  // 왜: 학사/프리즘 탭에 따라 화면 동작(배지, 관리 버튼)을 바꾸기 위해 소스 타입을 들고 있습니다.
  sourceType: 'haksa' | 'prism';
  courseId: string;
  courseType: string;
  subjectName: string;
  programId: number;
  programName: string;
  period: string;
  students: number;
  status: '대기' | '신청기간' | '학습기간' | '종료' | '-';
  // ===== 학사 View 25개 필드 =====
  haksaCategory?: string;        // 강좌형태
  haksaDeptName?: string;        // 학과/전공 이름
  haksaWeek?: string;            // 주차
  haksaOpenTerm?: string;        // 학기
  haksaCourseCode?: string;      // 강좌코드
  haksaVisible?: string;         // 강좌 폐강 여부 (Y=정상, N=폐강)
  haksaStartdate?: string;       // 강좌시작일
  haksaBunbanCode?: string;      // 분반코드
  haksaGrade?: string;           // 학년
  haksaGradName?: string;        // 단과대학 이름
  haksaDayCd?: string;           // 강의 요일
  haksaClassroom?: string;       // 강의실 정보
  haksaCurriculumCode?: string;  // 과목구분 코드
  haksaCourseEname?: string;     // 강좌명(영문)
  haksaTypeSyllabus?: string;    // 강의계획서 구분
  haksaOpenYear?: string;        // 연도
  haksaDeptCode?: string;        // 학과/전공 코드
  haksaCourseName?: string;      // 강좌명(한글)
  haksaGroupCode?: string;       // 학부/대학원 구분
  haksaEnddate?: string;         // 강좌종료일
  haksaEnglish?: string;         // 영문 강좌 여부
  haksaHour1?: string;           // 강의 시간
  haksaCurriculumName?: string;  // 과목구분 이름
  haksaGradCode?: string;        // 단과대학 코드
  haksaIsSyllabus?: string;      // 강의계획서 존재여부
}


type TabType = 'haksa' | 'prism';

interface MyCoursesListProps {
  routeSubPath?: string;
  routeParams?: Record<string, string>;
  onRouteChange?: (next: { subPath?: string; params: Record<string, string> }) => void;
}

const COURSE_MANAGEMENT_TAB_IDS: CourseManagementTabId[] = [
  'info',
  'info-basic',
  'info-evaluation',
  'info-completion',
  'curriculum',
  'students',
  'attendance',
  'exam',
  'assignment',
  'assignment-management',
  'assignment-feedback',
  'materials',
  'qna',
  'grades',
  'completion',
];
const COURSE_MANAGEMENT_TAB_SET = new Set<string>(COURSE_MANAGEMENT_TAB_IDS);

const isSameParams = (a: Record<string, string> = {}, b: Record<string, string> = {}) => {
  const aKeys = Object.keys(a);
  const bKeys = Object.keys(b);
  if (aKeys.length !== bKeys.length) return false;
  for (const key of aKeys) {
    if (a[key] !== b[key]) return false;
  }
  return true;
};

// 단과대학 옵션 (캠퍼스 이름만)
const GRAD_OPTIONS = [
  '전체',
  // I대학
  '서울정수', '서울강서', '성남', '분당융합', '제주',
  // II대학
  '인천', '남인천', '화성', '광명융합',
  // III대학
  '춘천', '원주', '강릉',
  // IV대학
  '대전', '청주', '아산', '충남', '충주',
  // V대학
  '광주', '전북', '전남', '익산', '순천',
  // VI대학
  '대구', '구미', '남대구', '포항', '영주', '영남융합기술',
  // VII대학
  '창원', '부산', '울산', '동부산', '진주', '석유화학공정',
  // 특성화
  '반도체융합', '바이오', '로봇', '항공', '신기술교육원',
];

// 과목구분 옵션
const CURRICULUM_OPTIONS = ['전체', '전공필수', '전공교과', '전공선택', '교양선택', '교양교과', '교양필수'];

// 유형 옵션
const CATEGORY_OPTIONS = ['전체', 'off', 'elearning'];

export function MyCoursesList({ routeSubPath, routeParams, onRouteChange }: MyCoursesListProps) {
  const currentYear = String(new Date().getFullYear());

  // 왜: URL 변경(뒤로가기 포함)과 화면 상태 변경이 서로 꼬이지 않도록, 현재 라우트 값을 ref로 관리합니다.
  const routeRef = useRef<{ subPath?: string; params: Record<string, string> }>({
    subPath: routeSubPath ?? undefined,
    params: routeParams ?? {},
  });
  routeRef.current = { subPath: routeSubPath ?? undefined, params: routeParams ?? {} };

  const pushRoute = useCallback((next: { subPath?: string; params: Record<string, string> }) => {
    if (!onRouteChange) return;
    const current = routeRef.current;
    if (current.subPath === next.subPath && isSameParams(current.params, next.params)) return;
    onRouteChange(next);
  }, [onRouteChange]);

  const parseNumberParam = useCallback((value: string | undefined, fallback: number) => {
    // 왜: 잘못된 주소 값이 들어와도 화면이 깨지지 않게 기본값으로 되돌립니다.
    const parsed = Number(value);
    if (Number.isNaN(parsed) || parsed <= 0) return fallback;
    return Math.floor(parsed);
  }, []);

  const initialTab =
    // 왜: 목록 탭(haksa/prism)과 관리 탭(info/attendance/...)이 같은 키(tab)를 쓰면 서로 덮어써서 화면이 흔들릴 수 있습니다.
    // 그래서 목록은 source(listTab)로 먼저 읽고, 예전 주소(tab=prism/haksa)도 호환으로만 처리합니다.
    routeParams?.source === 'prism' || routeParams?.source === 'haksa'
      ? (routeParams.source as TabType)
      : routeParams?.listTab === 'prism' || routeParams?.listTab === 'haksa'
        ? (routeParams.listTab as TabType)
        : routeParams?.tab === 'prism' || routeParams?.tab === 'haksa'
          ? (routeParams.tab as TabType)
          : 'haksa';
  const initialYear = routeParams?.year ?? currentYear;
  const initialKeyword = routeParams?.keyword ?? '';
  const initialPage = parseNumberParam(routeParams?.page, 1);
  const initialPageSize = parseNumberParam(routeParams?.pageSize, 20);
  const initialSortOrder = routeParams?.sortOrder === 'asc' ? 'asc' : 'desc';

  const [activeTab, setActiveTab] = useState<TabType>(initialTab); // 기본 탭: 학사
  const [yearOptions, setYearOptions] = useState<string[]>(['전체', currentYear]);
  const [year, setYear] = useState(initialYear);
  const [courseType, setCourseType] = useState(routeParams?.courseType ?? '전체');
  const [status, setStatus] = useState(routeParams?.status ?? '전체');
  const [searchTerm, setSearchTerm] = useState(initialKeyword);
  const [searchKeyword, setSearchKeyword] = useState(initialKeyword);
  const [selectedCourse, setSelectedCourse] = useState<Course | null>(null);
  const [selectedCourseTab, setSelectedCourseTab] = useState<CourseManagementTabId | null>(null);
  const [resolvingCourseId, setResolvingCourseId] = useState<string | null>(null);
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadedTab, setLoadedTab] = useState<TabType | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [page, setPage] = useState(initialPage);
  const [pageSize, setPageSize] = useState(initialPageSize);
  const [totalCount, setTotalCount] = useState(0);

  // 학사 탭 전용 필터
  const [haksaCategory, setHaksaCategory] = useState(routeParams?.haksaCategory ?? '전체'); // 유형: off/elearning
  const [haksaGrad, setHaksaGrad] = useState(routeParams?.haksaGrad ?? '전체'); // 단과대학
  const [haksaCurriculum, setHaksaCurriculum] = useState(routeParams?.haksaCurriculum ?? '전체'); // 과목구분
  const [sortOrder, setSortOrder] = useState<'desc' | 'asc'>(initialSortOrder); // 정렬 순서
  const autoSelectStateRef = useRef<{
    key: string;
    stage: 'init' | 'switched' | 'widened' | 'searched' | 'done';
    triedSources: { prism: boolean; haksa: boolean };
  } | null>(null);

  const normalizeText = (value?: string) => (value || '').toLowerCase().replace(/\s+/g, ' ').trim();
  const buildHaksaCourseId = (row: any) => {
    // 왜: 학사 과목은 (강좌코드/연도/학기/분반/그룹) 5종 키로 식별되는데,
    //     서버에서 내려주는 id가 환경/버전에 따라 중복될 수 있어(예: 연도/학기 누락),
    //     React 목록에서 key 충돌이 나면 클릭한 행과 다른 과목이 열리는 문제가 생깁니다.
    //     그래서 화면에서는 5종 키를 조합한 "항상 유일한 id"를 만들어 사용합니다.
    const courseCode = String(row?.haksa_course_code ?? '').trim();
    const openYear = String(row?.haksa_open_year ?? '').trim();
    const openTerm = String(row?.haksa_open_term ?? '').trim();
    const bunbanCode = String(row?.haksa_bunban_code ?? '').trim();
    const groupCode = String(row?.haksa_group_code ?? '').trim();

    const parts = [courseCode, openYear, openTerm, bunbanCode, groupCode].filter(Boolean);
    if (parts.length === 5) return `H_${parts.join('_')}`;

    // 왜: 일부 필드가 비어 있는 예외 데이터(테스트/초기 동기화 전)가 있을 수 있어 안전한 fallback을 둡니다.
    const fallback = String(row?.course_id_conv ?? row?.course_cd ?? row?.id ?? '').trim();
    return `H_${courseCode || 'UNKNOWN'}_${bunbanCode || '0'}_${fallback || '0'}`;
  };

  const mapRowToCourse = useCallback((row: any, fallbackSource: TabType): Course => {
    const sourceType = row?.source_type === 'haksa' || row?.source_type === 'prism' ? row.source_type : fallbackSource;
    const statusLabel = (row.status_label as Course['status']) ?? '대기';
    const typeParts = [
      (row.course_type_conv || '').trim(),
      (row.onoff_type_conv || '').trim(),
    ].filter(Boolean);
    const isHaksa = sourceType === 'haksa';
    const idValue = isHaksa ? (row.id ? String(row.id) : buildHaksaCourseId(row)) : String(row.id);
    const mappedCourseId = row.mapped_course_id ? Number(row.mapped_course_id) : undefined;

    return {
      id: idValue,
      mappedCourseId: mappedCourseId && Number.isFinite(mappedCourseId) ? mappedCourseId : undefined,
      sourceType,
      courseId: row.course_id_conv || row.course_cd || String(row.id),
      courseType: typeParts.length > 0 ? typeParts.join(' / ') : '미지정',
      subjectName: row.course_nm_conv || row.subject_nm_conv || row.course_nm || '-',
      programId: Number(row.program_id ?? 0),
      programName: row.program_nm_conv || '-',
      period: row.period_conv || '-',
      students: Number(row.student_cnt ?? 0),
      status: statusLabel,
      // ===== 학사 View 25개 필드 =====
      haksaCategory: row.haksa_category || '',
      haksaDeptName: row.haksa_dept_name || '',
      haksaWeek: row.haksa_week || '',
      haksaOpenTerm: row.haksa_open_term || '',
      haksaCourseCode: row.haksa_course_code || '',
      haksaVisible: row.haksa_visible || '',
      haksaStartdate: row.haksa_startdate || '',
      haksaBunbanCode: row.haksa_bunban_code || '',
      haksaGrade: row.haksa_grade || '',
      haksaGradName: row.haksa_grad_name || '',
      haksaDayCd: row.haksa_day_cd || '',
      haksaClassroom: row.haksa_classroom || '',
      haksaCurriculumCode: row.haksa_curriculum_code || '',
      haksaCourseEname: row.haksa_course_ename || '',
      haksaTypeSyllabus: row.haksa_type_syllabus || '',
      haksaOpenYear: row.haksa_open_year || '',
      haksaDeptCode: row.haksa_dept_code || '',
      haksaCourseName: row.haksa_course_name || '',
      haksaGroupCode: row.haksa_group_code || '',
      haksaEnddate: row.haksa_enddate || '',
      haksaEnglish: row.haksa_english || '',
      haksaHour1: row.haksa_hour1 || '',
      haksaCurriculumName: row.haksa_curriculum_name || '',
      haksaGradCode: row.haksa_grad_code || '',
      haksaIsSyllabus: row.haksa_is_syllabus || '',
    };
  }, []);

  const getRouteParam = useCallback((keys: string[]) => {
    for (const key of keys) {
      const value = routeParams?.[key];
      if (value) return value;
    }
    return '';
  }, [routeParams]);

  const buildListRouteParams = useCallback(() => {
    // 왜: 목록 화면의 상태를 주소에 담아 뒤로가기/직접 이동이 되게 합니다.
    const params: Record<string, string> = {};
    if (activeTab !== 'haksa') params.source = activeTab;
    if (year) params.year = year;
    if (searchKeyword) params.keyword = searchKeyword;
    if (page > 1) params.page = String(page);
    if (pageSize !== 20) params.pageSize = String(pageSize);

    if (activeTab === 'prism') {
      if (courseType !== '전체') params.courseType = courseType;
      if (status !== '전체') params.status = status;
    }

    if (activeTab === 'haksa') {
      if (haksaCategory !== '전체') params.haksaCategory = haksaCategory;
      if (haksaGrad !== '전체') params.haksaGrad = haksaGrad;
      if (haksaCurriculum !== '전체') params.haksaCurriculum = haksaCurriculum;
      if (sortOrder !== 'desc') params.sortOrder = sortOrder;
    }

    return params;
  }, [
    activeTab,
    courseType,
    haksaCategory,
    haksaCurriculum,
    haksaGrad,
    page,
    pageSize,
    searchKeyword,
    sortOrder,
    status,
    year,
  ]);

  useEffect(() => {
    if (!onRouteChange) return;
    if (routeSubPath === 'manage') return;
    if (selectedCourse) return;
    pushRoute({ subPath: undefined, params: buildListRouteParams() });
  }, [buildListRouteParams, onRouteChange, pushRoute, routeSubPath, selectedCourse]);

  useEffect(() => {
    if (routeSubPath === 'manage') return;
    const nextTab =
      routeParams?.source === 'prism' || routeParams?.source === 'haksa'
        ? (routeParams.source as TabType)
        : routeParams?.listTab === 'prism' || routeParams?.listTab === 'haksa'
          ? (routeParams.listTab as TabType)
          : routeParams?.tab === 'prism' || routeParams?.tab === 'haksa'
            ? (routeParams.tab as TabType)
            : 'haksa';
    const nextYear = routeParams?.year ?? currentYear;
    const nextKeyword = routeParams?.keyword ?? '';
    const nextPage = parseNumberParam(routeParams?.page, 1);
    const nextPageSize = parseNumberParam(routeParams?.pageSize, 20);
    const nextCourseType = routeParams?.courseType ?? '전체';
    const nextStatus = routeParams?.status ?? '전체';
    const nextHaksaCategory = routeParams?.haksaCategory ?? '전체';
    const nextHaksaGrad = routeParams?.haksaGrad ?? '전체';
    const nextHaksaCurriculum = routeParams?.haksaCurriculum ?? '전체';
    const nextSortOrder = routeParams?.sortOrder === 'asc' ? 'asc' : 'desc';

    if (nextTab !== activeTab) setActiveTab(nextTab);
    if (nextYear !== year) setYear(nextYear);
    if (nextKeyword !== searchTerm) {
      setSearchTerm(nextKeyword);
      setSearchKeyword(nextKeyword);
    }
    if (nextPage !== page) setPage(nextPage);
    if (nextPageSize !== pageSize) setPageSize(nextPageSize);
    if (nextCourseType !== courseType) setCourseType(nextCourseType);
    if (nextStatus !== status) setStatus(nextStatus);
    if (nextHaksaCategory !== haksaCategory) setHaksaCategory(nextHaksaCategory);
    if (nextHaksaGrad !== haksaGrad) setHaksaGrad(nextHaksaGrad);
    if (nextHaksaCurriculum !== haksaCurriculum) setHaksaCurriculum(nextHaksaCurriculum);
    if (nextSortOrder !== sortOrder) setSortOrder(nextSortOrder);
  }, [
    currentYear,
    parseNumberParam,
    routeParams,
    routeSubPath,
  ]);

  useEffect(() => {
    let cancelled = false;

    // 왜: 년도 필터 옵션을 하드코딩하면(2024/2023/2022), 실제 데이터와 안 맞아 "없는 년도"를 고르게 될 수 있습니다.
    const fetchYears = async () => {
      try {
        const res = await tutorLmsApi.getCourseYears();
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        const years = (res.rst_data ?? [])
          .map((r) => String(r.year || '').trim())
          .filter(Boolean);

        const uniq = Array.from(new Set(years)).sort((a, b) => b.localeCompare(a));
        const options = ['전체', ...uniq];

        if (cancelled) return;
        setYearOptions(options.length > 1 ? options : ['전체', currentYear]);
        setYear((prev) => {
          if (prev && options.includes(prev)) return prev;
          return uniq[0] ? uniq[0] : '전체';
        });
      } catch (e) {
        // 왜: 년도 옵션 조회 실패는 치명적이지 않으므로, 기본값(현재년도/전체)으로 폴백합니다.
        if (!cancelled) setYearOptions(['전체', currentYear]);
      }
    };

    void fetchYears();
    return () => {
      cancelled = true;
    };
  }, [currentYear]);

  // 왜: 탭에 따라 필터 기준이 달라서 분기 처리합니다.
  const filteredCourses = useMemo(() => {
    if (activeTab === 'haksa') {
      return courses.filter((course) => {
        const matchesCategory = haksaCategory === '전체' || (course.haksaCategory || '').toLowerCase() === haksaCategory.toLowerCase();
        const matchesGrad = haksaGrad === '전체' || (course.haksaGradName || '').includes(haksaGrad);
        const matchesCurriculum = haksaCurriculum === '전체' || (course.haksaCurriculumName || '') === haksaCurriculum;
        return matchesCategory && matchesGrad && matchesCurriculum;
      });
    }

    const matchesCourseType = courseType === '전체' || course.courseType === courseType;
    const matchesStatus = status === '전체' || course.status === status;
    return courses.filter((course) => matchesCourseType && matchesStatus);
  }, [activeTab, courses, courseType, status, haksaCategory, haksaGrad, haksaCurriculum]);

  useEffect(() => {
    const timer = setTimeout(() => {
      setSearchKeyword(searchTerm.trim());
    }, 300);
    return () => clearTimeout(timer);
  }, [searchTerm]);

  useEffect(() => {
    // 왜: 필터/탭 변경 시 페이지가 어긋나지 않도록 첫 페이지로 복귀합니다.
    setPage(1);
  }, [activeTab, year, searchKeyword, pageSize, haksaCategory, haksaGrad, haksaCurriculum, sortOrder]);

  useEffect(() => {
    let cancelled = false;

    const fetchCourses = async () => {
      setLoading(true);
      setErrorMessage(null);
      try {
        // activeTab에 따라 getMyCoursesCombined 호출
        const res = await tutorLmsApi.getMyCoursesCombined({
          tab: activeTab,
          year: year === '전체' ? undefined : year,
          keyword: searchKeyword || undefined,
          page,
          pageSize,
          haksaCategory: activeTab === 'haksa' && haksaCategory !== '전체' ? haksaCategory : undefined,
          haksaGrad: activeTab === 'haksa' && haksaGrad !== '전체' ? haksaGrad : undefined,
          haksaCurriculum: activeTab === 'haksa' && haksaCurriculum !== '전체' ? haksaCurriculum : undefined,
          sortOrder: activeTab === 'haksa' ? sortOrder : undefined,
        });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        const rows = res.rst_data ?? [];
        const serverTotal = Number(res.rst_total_count ?? rows.length);
        const mapped: Course[] = rows.map((row) => mapRowToCourse(row, activeTab));

        if (!cancelled) {
          setCourses(mapped);
          setTotalCount(Number.isNaN(serverTotal) ? rows.length : serverTotal);
        }
      } catch (e) {
        if (!cancelled) setErrorMessage(e instanceof Error ? e.message : '조회 중 오류가 발생했습니다.');
      } finally {
        if (!cancelled) {
          // 왜: 자동 선택 로직에서 현재 탭의 데이터가 준비됐는지 판단하기 위해 기록합니다.
          setLoading(false);
          setLoadedTab(activeTab);
        }
      }
    };

    fetchCourses();
    return () => {
      cancelled = true;
    };
  }, [year, activeTab, searchKeyword, page, pageSize, haksaCategory, haksaGrad, haksaCurriculum, sortOrder, mapRowToCourse]); // activeTab 의존성 추가

  useEffect(() => {
    const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
    if (page > totalPages) setPage(totalPages);
  }, [totalCount, pageSize, page]);

  const courseTypeOptions = useMemo(() => {
    const types = Array.from(new Set(courses.map((c) => c.courseType).filter((t) => t && t !== '미지정'))).sort((a, b) =>
      a.localeCompare(b)
    );
    return ['전체', ...types];
  }, [courses]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case '대기':
        return 'bg-gray-100 text-gray-700';
      case '신청기간':
        return 'bg-blue-100 text-blue-700';
      case '학습기간':
        return 'bg-green-100 text-green-700';
      case '종료':
        return 'bg-gray-200 text-gray-600';
      default:
        return 'bg-gray-100 text-gray-700';
    }
  };

  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const pageNumbers = useMemo(() => {
    const start = Math.max(1, page - 2);
    const end = Math.min(totalPages, page + 2);
    return Array.from({ length: end - start + 1 }, (_, idx) => start + idx);
  }, [page, totalPages]);

  const findCourseBySelection = (targetIdRaw: string, targetName?: string) => {
    const normalizedTargetId = normalizeText(targetIdRaw);
    const targetId = Number(targetIdRaw);
    const normalizedTargetName = normalizeText(targetName);

    // 왜: URL로 넘어오는 courseName은 "부분 문자열"인 경우가 있어,
    //     includes 매칭을 먼저 쓰면 '시드 학사과목(2026)'처럼 공통 접두어를 가진 과목에서
    //     '... B'가 먼저 잡혀서 엉뚱한 과목이 열릴 수 있습니다.
    //     그래서 이름이 있을 때는 "정확히 같은 이름"을 최우선으로 매칭합니다.
    if (normalizedTargetName) {
      const exact = courses.find((course) => {
        const subjectName = normalizeText(course.subjectName);
        const programName = normalizeText(course.programName);
        return subjectName === normalizedTargetName || programName === normalizedTargetName;
      });
      if (exact) return exact;
    }

    return courses.find((course) => {
      const courseIdNum = Number(course.id);
      const mappedIdNum = Number(course.mappedCourseId ?? NaN);
      const convIdNum = Number(course.courseId);
      const rawIdMatched =
        normalizedTargetId &&
        (normalizeText(course.id) === normalizedTargetId ||
          normalizeText(course.courseId) === normalizedTargetId ||
          normalizeText(String(course.mappedCourseId ?? '')) === normalizedTargetId);
      const idMatched =
        (!Number.isNaN(targetId) && courseIdNum === targetId) ||
        (!Number.isNaN(targetId) && mappedIdNum === targetId) ||
        (!Number.isNaN(targetId) && convIdNum === targetId) ||
        rawIdMatched;
      if (idMatched) return true;

      if (!normalizedTargetName) return false;
      const subjectName = normalizeText(course.subjectName);
      const programName = normalizeText(course.programName);
      return (
        subjectName === normalizedTargetName ||
        subjectName.includes(normalizedTargetName) ||
        normalizedTargetName.includes(subjectName) ||
        programName === normalizedTargetName ||
        programName.includes(normalizedTargetName)
      );
    });
  };

  const handleSelectCourse = useCallback(async (course: Course, targetTab?: CourseManagementTabId) => {
    setSelectedCourseTab(targetTab ?? null);
    if (course.sourceType !== 'haksa') {
      setSelectedCourse(course);
      return;
    }

    if (course.mappedCourseId && course.mappedCourseId > 0) {
      setSelectedCourse(course);
      return;
    }

    if (!course.haksaCourseCode || !course.haksaOpenYear || !course.haksaOpenTerm || !course.haksaBunbanCode || !course.haksaGroupCode) {
      alert('학사 과목 키가 비어 있어 과정 매핑을 진행할 수 없습니다.');
      return;
    }

    setResolvingCourseId(course.id);
    try {
      const res = await tutorLmsApi.resolveHaksaCourse({
        courseCode: course.haksaCourseCode,
        openYear: course.haksaOpenYear,
        openTerm: course.haksaOpenTerm,
        bunbanCode: course.haksaBunbanCode,
        groupCode: course.haksaGroupCode,
      });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);

      const payload = Array.isArray(res.rst_data) ? res.rst_data[0] : res.rst_data;
      const mapped = Number(payload?.mapped_course_id ?? 0);
      if (!mapped || Number.isNaN(mapped)) throw new Error('매핑된 과정ID를 찾지 못했습니다.');

      setSelectedCourse({ ...course, mappedCourseId: mapped });
    } catch (e) {
      alert(e instanceof Error ? e.message : '학사 과목 매핑 중 오류가 발생했습니다.');
    } finally {
      setResolvingCourseId(null);
    }
  }, []);

  // 왜: 주소에서 넘어온 과목 정보를 자동 선택 로직에 맞춰 정리합니다.
  const routeCourseId = getRouteParam(['courseId', 'course_id', 'id']);
  const routeCourseName = getRouteParam(['courseName', 'course_nm', 'courseNameConv', 'name']);
  const routeDirectParam = getRouteParam(['direct', 'directOpen', 'direct_open']);
  const isDirectOpen = routeSubPath === 'manage' && routeDirectParam === '1';
  const routeQnaPostIdRaw = getRouteParam(['qnaPostId', 'qna_post_id', 'postId', 'post_id']);
  const routeQnaPostId = (() => {
    // 왜: Q&A 상세 바로가기는 숫자 post_id가 필요합니다(문자열이면 파싱).
    const parsed = Number(routeQnaPostIdRaw);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined;
  })();
  const rawTabParam = getRouteParam(['cmTab', 'cm_tab', 'tab', 'targetTab', 'tab_id']);
  const routeTargetTab =
    COURSE_MANAGEMENT_TAB_SET.has(rawTabParam) ? (rawTabParam as CourseManagementTabId) : undefined;
  const rawSourceParam = getRouteParam(['source', 'source_type', 'sourceType', 'listTab']);
  const routeSourceType =
    rawSourceParam === 'haksa' || rawSourceParam === 'prism'
      ? rawSourceParam
      : (!routeTargetTab && (rawTabParam === 'haksa' || rawTabParam === 'prism') ? rawTabParam : undefined);
  const routeSelection =
    routeSubPath === 'manage' && (routeCourseId || routeCourseName)
      ? {
          courseId: routeCourseId,
          courseName: routeCourseName,
          targetTab: routeTargetTab,
          sourceType: routeSourceType,
        }
      : null;

  useEffect(() => {
    if (!isDirectOpen || !routeSelection) return;
    if (!routeSelection.courseId) return;
    let cancelled = false;

    const fetchDirectCourse = async () => {
      try {
        const courseIdNum = Number(routeSelection.courseId);
        if (!Number.isFinite(courseIdNum) || courseIdNum <= 0) {
          throw new Error('과목 ID가 올바르지 않습니다.');
        }
        const res = await tutorLmsApi.getCourseResolve({
          courseId: courseIdNum,
          sourceType: routeSelection.sourceType,
        });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);

        const payload = Array.isArray(res.rst_data) ? res.rst_data[0] : res.rst_data;
        if (!payload) throw new Error('과목 정보를 찾지 못했습니다.');

        const mapped = mapRowToCourse(payload, (routeSelection.sourceType ?? 'prism') as TabType);
        if (!cancelled) {
          setSelectedCourseTab(routeSelection.targetTab ?? null);
          setSelectedCourse(mapped);
        }
      } catch (e) {
        if (!cancelled) {
          setErrorMessage(e instanceof Error ? e.message : '과목 조회 중 오류가 발생했습니다.');
        }
      }
    };

    void fetchDirectCourse();
    return () => {
      cancelled = true;
    };
  }, [isDirectOpen, mapRowToCourse, routeSelection]);

  useEffect(() => {
    if (!routeSelection) return;
    if (isDirectOpen) return;
    if (selectedCourse) {
      const selectionId = normalizeText(routeSelection.courseId);
      const selectionName = normalizeText(routeSelection.courseName);
      const selectedId = normalizeText(selectedCourse.id);
      const selectedCourseId = normalizeText(selectedCourse.courseId);
      const selectedName = normalizeText(selectedCourse.subjectName);
      const selectedMappedId = normalizeText(String(selectedCourse.mappedCourseId ?? ''));

      const idMatched =
        selectionId &&
        (selectedId === selectionId || selectedCourseId === selectionId || (selectedMappedId && selectedMappedId === selectionId));
      const nameMatched = selectionName && selectedName === selectionName;
      if (idMatched || nameMatched) return;
    }
    if (loadedTab !== activeTab) return;

    const targetIdRaw = routeSelection.courseId;
    const normalizedTargetId = normalizeText(targetIdRaw);
    const hasId = Boolean(normalizedTargetId);
    const hasName = Boolean(normalizeText(routeSelection.courseName));
    if (!hasId && !hasName) return;

    const targetId = Number(targetIdRaw);

    const selectionKey = `${normalizedTargetId}-${normalizeText(routeSelection.courseName)}-${routeSelection.targetTab ?? ''}`;
    if (!autoSelectStateRef.current || autoSelectStateRef.current.key !== selectionKey) {
      autoSelectStateRef.current = {
        key: selectionKey,
        stage: 'init',
        triedSources: { prism: false, haksa: false },
      };
    }

    const state = autoSelectStateRef.current;
    const matched = findCourseBySelection(targetIdRaw, routeSelection.courseName);

    if (matched) {
      // 왜: 주소로 넘어온 과목은 바로 상세 탭으로 열어줍니다.
      state.stage = 'done';
      void handleSelectCourse(matched, routeSelection.targetTab);
      return;
    }

    if (state.stage === 'init') {
      const targetSource = routeSelection.sourceType;
      if (targetSource === 'haksa' || targetSource === 'prism') {
        state.triedSources[targetSource] = true;
        if (activeTab !== targetSource) {
          // 왜: 주소에 있는 소스 탭과 실제 목록 탭을 맞춰서 검색합니다.
          state.stage = 'switched';
          setActiveTab(targetSource);
          return;
        }
      } else {
        // 왜: 소스 타입이 없으면(대시보드 등), 프리즘→학사 순으로 한 번씩만 찾아봅니다.
        state.triedSources.prism = true;
        if (activeTab !== 'prism') {
          state.stage = 'switched';
          setActiveTab('prism');
          return;
        }
      }
    }

    if (state.stage === 'switched' || state.stage === 'init') {
      // 왜: 필터/페이지 때문에 못 찾는 경우가 있어 조건을 넓힙니다.
      state.stage = 'widened';
      setYear('전체');
      setCourseType('전체');
      setStatus('전체');
      setHaksaCategory('전체');
      setHaksaGrad('전체');
      setHaksaCurriculum('전체');
      setSortOrder('desc');
      // 왜: 목록이 페이지네이션되어 있어, 바로가기는 최대한 많이 불러와 찾습니다.
      setPageSize(100);
      setPage(1);
      setSearchTerm('');
      setSearchKeyword('');
      return;
    }

    if (state.stage === 'widened') state.stage = 'searched';

    if (state.stage === 'searched' && !loading) {
      const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));

      // 왜: 1페이지에 없을 수 있으니, 다음 페이지를 자동으로 넘기며 찾습니다(과도한 요청 방지용 상한 포함).
      if (page < totalPages && page < 10) {
        setPage((prev) => prev + 1);
        return;
      }

      const otherSource: TabType = activeTab === 'prism' ? 'haksa' : 'prism';
      if (!state.triedSources[otherSource]) {
        // 왜: 한쪽 탭에 없을 수 있으니, 다른 탭도 한 번만 더 확인합니다.
        state.triedSources[otherSource] = true;
        state.stage = 'switched';
        setActiveTab(otherSource);
        return;
      }

      state.stage = 'done';
    }
  }, [activeTab, handleSelectCourse, isDirectOpen, loadedTab, loading, page, pageSize, routeSelection, selectedCourse, totalCount]);

  const lastRouteTargetTabRef = useRef<CourseManagementTabId | undefined>(routeTargetTab);
  useEffect(() => {
    // 왜: "탭 클릭 → selectedCourseTab 변경 → URL(cmTab) 변경" 순서로 흘러가는데,
    // 중간에 URL의 "예전 탭" 값을 selectedCourseTab에 덮어쓰면 화면이 깜빡이며 클릭이 무시됩니다.
    // 그래서 실제로 URL 탭 값이 바뀐 경우(뒤로가기/직접 주소 변경)만 selectedCourseTab을 동기화합니다.
    if (routeSubPath !== 'manage') {
      lastRouteTargetTabRef.current = routeTargetTab;
      return;
    }

    if (routeTargetTab === lastRouteTargetTabRef.current) return;
    lastRouteTargetTabRef.current = routeTargetTab;
    if (!routeTargetTab) return;
    setSelectedCourseTab(routeTargetTab);
  }, [routeSubPath, routeTargetTab]);

  useEffect(() => {
    if (!onRouteChange || !selectedCourse) return;
    const nextTab = selectedCourseTab ?? routeTargetTab ?? 'info-basic';
    const courseNameParam = selectedCourse.subjectName || selectedCourse.courseId;
    pushRoute({
      subPath: 'manage',
      params: {
        courseId: selectedCourse.id,
        source: selectedCourse.sourceType,
        cmTab: nextTab,
        courseName: courseNameParam,
      },
    });
  }, [onRouteChange, pushRoute, routeTargetTab, selectedCourse, selectedCourseTab]);

  useEffect(() => {
    if (routeSubPath === 'manage') return;
    if (!selectedCourse) return;
    // 왜: 주소가 목록으로 돌아오면 상세 선택도 초기화합니다.
    setSelectedCourse(null);
    setSelectedCourseTab(null);
  }, [routeSubPath, selectedCourse]);

  // 선택된 과목이 있으면 관리 페이지 표시
  if (selectedCourse) {
    return (
      <CourseManagement
        course={selectedCourse}
        initialTab={selectedCourseTab ?? routeTargetTab ?? undefined}
        initialQnaPostId={routeSubPath === 'manage' ? routeQnaPostId : undefined}
        onTabChange={(tabId) => setSelectedCourseTab(tabId)}
        onBack={() => {
          setSelectedCourse(null);
          setSelectedCourseTab(null);
          pushRoute({ subPath: undefined, params: buildListRouteParams() });
        }}
      />
    );
  }

  return (
    <div className="max-w-7xl mx-auto">
      <div className="mb-8">
        <h2 className="text-gray-900 mb-2">담당 과목</h2>
        <p className="text-gray-600">담당하고 있는 과목 목록을 확인하고 관리합니다.</p>
      </div>

      {/* 탭 영역 */}
      <div className="flex gap-2 mb-4">
        <button
          onClick={() => setActiveTab('haksa')}
          className={`px-6 py-2.5 rounded-lg font-medium transition-all ${
            activeTab === 'haksa'
              ? 'bg-blue-600 text-white shadow-md'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          정규
        </button>
        <button
          onClick={() => setActiveTab('prism')}
          className={`px-6 py-2.5 rounded-lg font-medium transition-all ${
            activeTab === 'prism'
              ? 'bg-blue-600 text-white shadow-md'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          비정규
        </button>
      </div>

      {/* 필터 영역 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        {activeTab === 'haksa' ? (
          /* 학사 탭 필터: 유형, 단과대학, 과목구분, 정렬, 검색 */
          <div className="grid grid-cols-6 gap-4 mb-4">
            <div>
              <label className="block text-sm text-gray-700 mb-2">년도</label>
              <select
                value={year}
                onChange={(e) => setYear(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {yearOptions.map((y) => (
                  <option key={y} value={y}>
                    {y}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm text-gray-700 mb-2">유형</label>
              <select
                value={haksaCategory}
                onChange={(e) => setHaksaCategory(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {CATEGORY_OPTIONS.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm text-gray-700 mb-2">단과대학</label>
              <select
                value={haksaGrad}
                onChange={(e) => setHaksaGrad(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {GRAD_OPTIONS.map((g) => (
                  <option key={g} value={g}>
                    {g}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm text-gray-700 mb-2">과목구분</label>
              <select
                value={haksaCurriculum}
                onChange={(e) => setHaksaCurriculum(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {CURRICULUM_OPTIONS.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm text-gray-700 mb-2">정렬</label>
              <select
                value={sortOrder}
                onChange={(e) => setSortOrder(e.target.value as 'desc' | 'asc')}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="desc">강좌코드 내림차순</option>
                <option value="asc">강좌코드 오름차순</option>
              </select>
            </div>
            <div>
              <label className="block text-sm text-gray-700 mb-2">검색</label>
              <div className="relative">
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="과목명, 과정명, 과정ID 검색"
                  className="w-full px-4 py-2 pl-10 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              </div>
            </div>
          </div>
        ) : (
          /* 프리즘 탭 필터: 연도, 유형, 상태, 검색 */
          <div className="grid grid-cols-4 gap-4 mb-4">
            <div>
              <label className="block text-sm text-gray-700 mb-2">년도</label>
              <select
                value={year}
                onChange={(e) => setYear(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {yearOptions.map((y) => (
                  <option key={y} value={y}>
                    {y}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm text-gray-700 mb-2">유형</label>
              <select
                value={courseType}
                onChange={(e) => setCourseType(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {courseTypeOptions.map((t) => (
                  <option key={t} value={t}>
                    {t}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm text-gray-700 mb-2">상태</label>
              <select
                value={status}
                onChange={(e) => setStatus(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="전체">전체</option>
                <option value="대기">대기</option>
                <option value="신청기간">신청기간</option>
                <option value="학습기간">학습기간</option>
                <option value="종료">종료</option>
              </select>
            </div>
            <div>
              <label className="block text-sm text-gray-700 mb-2">검색</label>
              <div className="relative">
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="과목명, 과정명, 과정ID 검색"
                  className="w-full px-4 py-2 pl-10 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              </div>
            </div>
          </div>
        )}
      </div>

      {/* 과목 목록 테이블 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-4 py-3 text-left text-sm text-gray-700">No</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">요청</th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">과정ID</th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">유형</th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">과목명</th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">
                  {activeTab === 'haksa' ? '학과/전공' : '소속 과정명'}
                </th>
                <th className="px-4 py-3 text-left text-sm text-gray-700">기간</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">수강생</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">상태</th>
                <th className="px-4 py-3 text-center text-sm text-gray-700">관리</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {errorMessage ? (
                <tr>
                  <td colSpan={10} className="px-4 py-12 text-center text-gray-500">
                    <p>{errorMessage}</p>
                  </td>
                </tr>
              ) : loading ? (
                <tr>
                  <td colSpan={10} className="px-4 py-12 text-center text-gray-500">
                    <p>불러오는 중...</p>
                  </td>
                </tr>
              ) : filteredCourses.length > 0 ? (
                filteredCourses.map((course, index) => (
                  <tr key={course.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-4 text-sm text-gray-900">{(page - 1) * pageSize + index + 1}</td>
                    <td className="px-4 py-4 text-center">
                      <span className={`inline-flex px-2 py-0.5 text-xs rounded-full ${
                        course.sourceType === 'prism' ? 'bg-blue-100 text-blue-700' : 'bg-amber-100 text-amber-700'
                      }`}>
                        {course.sourceType === 'prism' ? 'LMS' : '학사'}
                      </span>
                    </td>
                    <td className="px-4 py-4 text-sm text-gray-900">{course.courseId}</td>
                    <td className="px-4 py-4 text-sm text-gray-600">
                      {course.sourceType === 'haksa' && course.haksaCategory 
                        ? course.haksaCategory 
                        : course.courseType}
                    </td>
                    <td className="px-4 py-4 text-sm text-gray-900">{course.subjectName}</td>
                    <td className="px-4 py-4 text-sm text-gray-600">
                      {course.sourceType === 'haksa' && course.haksaDeptName
                        ? course.haksaDeptName
                        : course.programName}
                    </td>
                    <td className="px-4 py-4 text-sm text-gray-600">{course.period}</td>
                    <td className="px-4 py-4 text-center">
                      <div className="flex items-center justify-center gap-1 text-sm text-gray-900">
                        <Users className="w-4 h-4 text-gray-500" />
                        <span>{course.students}</span>
                      </div>
                    </td>
                    <td className="px-4 py-4 text-center">
                      <span
                        className={`inline-flex px-3 py-1 text-xs rounded-full ${getStatusColor(
                          course.status
                        )}`}
                      >
                        {course.status}
                      </span>
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-center justify-center">
                        <button
                          className="flex items-center gap-1 px-4 py-1.5 text-xs text-blue-700 bg-blue-50 rounded hover:bg-blue-100 transition-colors disabled:opacity-60"
                          title="과목 관리"
                          onClick={() => void handleSelectCourse(course)}
                          disabled={resolvingCourseId === course.id}
                        >
                          <Settings className="w-4 h-4" />
                          <span>{resolvingCourseId === course.id ? '연동 중...' : '관리'}</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={10} className="px-4 py-12 text-center text-gray-500">
                    <p>검색 결과가 없습니다.</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* 페이지/카운트 */}
      <div className="mt-4 flex flex-wrap items-center justify-between gap-3 text-sm text-gray-600">
        <div className="flex items-center gap-2">
          <span>총</span>
          <span className="text-blue-600">{totalCount}</span>
          <span>개의 과목</span>
          <span className="text-gray-400">/ 현재 {filteredCourses.length}개 표시</span>
        </div>
        <div className="flex items-center gap-2">
          <label htmlFor="page-size" className="text-gray-600">페이지당</label>
          <select
            id="page-size"
            value={pageSize}
            onChange={(e) => setPageSize(Number(e.target.value))}
            className="px-2 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            {[20, 50, 100].map((size) => (
              <option key={size} value={size}>{size}</option>
            ))}
          </select>
        </div>
      </div>

      {/* 페이지네이션 */}
      <div className="mt-4 flex items-center justify-center gap-2">
        <button
          type="button"
          onClick={() => setPage(1)}
          disabled={page === 1}
          className="px-3 py-1.5 text-sm border border-gray-300 rounded-md disabled:opacity-40"
        >
          처음
        </button>
        <button
          type="button"
          onClick={() => setPage((prev) => Math.max(1, prev - 1))}
          disabled={page === 1}
          className="px-3 py-1.5 text-sm border border-gray-300 rounded-md disabled:opacity-40"
        >
          이전
        </button>
        {pageNumbers.map((num) => (
          <button
            key={num}
            type="button"
            onClick={() => setPage(num)}
            className={`px-3 py-1.5 text-sm border rounded-md ${
              num === page ? 'bg-blue-600 text-white border-blue-600' : 'border-gray-300'
            }`}
          >
            {num}
          </button>
        ))}
        <button
          type="button"
          onClick={() => setPage((prev) => Math.min(totalPages, prev + 1))}
          disabled={page === totalPages}
          className="px-3 py-1.5 text-sm border border-gray-300 rounded-md disabled:opacity-40"
        >
          다음
        </button>
        <button
          type="button"
          onClick={() => setPage(totalPages)}
          disabled={page === totalPages}
          className="px-3 py-1.5 text-sm border border-gray-300 rounded-md disabled:opacity-40"
        >
          끝
        </button>
      </div>
    </div>
  );
}
