  
**GrowAI LMS**

Artificial Neuron v2.0

**상세 분석 기반 적용 방안 수립서**

Real\_one\_stop\_service 프로젝트 소스 분석 및 통합 방안

| 프로젝트명 | 미래형 직업교육 플랫폼 임차 사업 (GrowAI-LMS) |
| :---: | :---- |
| **발주기관** | 한국폴리텍대학 |
| **사업규모** | 198,000,000원 (9\~12월, 4개월) |
| **대상 사용자** | 약 15,000명 (학생 \+ 교수자 \+ 관리자) |
| **작성일** | 2026년 2월 7일 |
| **문서 버전** | v1.0 |

# **목차**

**1\. 분석 개요**

1.1 분석 대상 현황

1.2 API 뷰테이블 8종 컬럼 현황

**2\. 항목별 상세 적용 방안**

2.1 차시 유효기간 (출결)

2.2 강좌 계획서 불러오기

2.3 개설정보 불러오기

2.4 대리출석 방지

2.5 성적 등록 뷰테이블

2.6 과제/Q\&A 피드백 일괄 출력

2.7 성적 기준 수정 불가

2.8 학위/비학위 DB 일관성

**3\. 통합 구현 로드맵**

3.1 Phase별 추진 계획

3.2 RFP 요구사항 대응 현황

**4\. 기술 아키텍처 적용 방안**

4.1 데이터 동기화 아키텍처

4.2 보안 요구사항 대응

**5\. 리스크 분석 및 대응 방안**

**6\. 결론 및 권고사항**

# **1\. 분석 개요**

본 문서는 D:\\Real\_one\_stop\_service 프로젝트의 8개 핵심 항목에 대한 상세 분석 결과를 바탕으로, API 뷰테이블 8종(162개 컬럼)과의 매핑 관계를 정리하고, RFP 20개 요구사항(SFR-001\~007)에 대한 구체적인 적용 방안을 수립한 문서입니다.

## **1.1 분석 대상 현황**

| 구분 | 완료 \[x\] | 부분구현 \[\~\] | 미구현 \[\!\] | 합계 |
| ----- | :---: | :---: | :---: | :---: |
| **항목 수** | 2건 | 3건 | 3건 | **8건** |
| **비율** | 25% | 37.5% | 37.5% | **100%** |

## **1.2 API 뷰테이블 8종 컬럼 현황**

| 뷰테이블 | 컬럼수 | 주요 데이터 |
| ----- | :---: | ----- |
| **LMS\_LECTPLAN\_NCS\_VIEW** | 22 | NCS 능력단위, 평가방법, 훈련시설 |
| **LMS\_LECTPLAN\_VIEW** | 17 | 주차별 강의계획, 강의실, 실습내용 |
| **LMS\_COURSE\_VIEW** | 28 | 강좌정보, 학과, 강의계획서, 학기 |
| **LMS\_MEMBER\_VIEW** | 22 | 회원정보, 캠퍼스, 연락처, 신분 |
| **LMS\_STUDENT\_VIEW** | 10 | 수강생 학번, 강좌코드, 분반 |
| **LMS\_PROFESSOR\_VIEW** | 11 | 교수 교번, 담당 강좌, 순번 |
| **COURSE\_INFO\_VIEW** | 25(13섹션) | 교과편성총괄표, 훈련과정 로드맵 |
| **채용공고\_VIEW** | 27 | 회사명, 직무, 고용형태, 복지, 자격증 |

총 162개 컬럼 (메타 필드 \_\_FIRST/\_\_LAST/\_\_ORD 포함)으로 Oracle DB VPN 연동을 통한 실시간 동기화 대상입니다.

# **2\. 항목별 상세 적용 방안**

## **2.1 차시 유효기간 (출결)**

| 상태 | ⚠️ 부분구현 | 우선순위 | 중 | 2주 |
| :---: | :---: | :---: | :---: | :---: |

| 소스 위치 | project/components/courseManagement/AttendanceTab.tsx |
| :---- | :---- |
| **현재 상태** | HaksaSessionItem 타입에 startDate/endDate/startTime/endTime 필드 존재. 출석은 "차시 수강기간 안에 제출/완료" 기준으로 판정. 별도 valid\_from/valid\_to 유효기간 필드 없음. |
| **연관 뷰테이블** | LMS\_LECTPLAN\_VIEW (LSN\_WEKORD, CREATE\_TIME, MODIFY\_TIME) LMS\_COURSE\_VIEW (STARTDATE, ENDDATE) |
| **RFP 요구사항** | SFR-005 (능동형 커리큘럼 개설 및 관리) |

**적용 과제 (4건)**

| T1.1 | LMS\_LECTPLAN\_VIEW의 LSN\_WEKORD \+ LMS\_COURSE\_VIEW의 STARTDATE/ENDDATE 기반으로 차시별 유효기간 자동 산출 로직 구현 |
| :---: | :---- |
| **T1.2** | AttendanceTab.tsx에 valid\_from/valid\_to 필드 추가 및 UI 유효기간 표시 컴포넌트 개발 |
| **T1.3** | 유효기간 만료 시 자동 결석 처리 배치 로직 (지각3회=결석1회 기존 로직 유지) |
| **T1.4** | 교수자가 차시별 유효기간을 수동 조정할 수 있는 관리 UI 추가 |

## **2.2 강좌 계획서 불러오기**

| 상태 | ❌ 미구현 | 우선순위 | 상 | 3주 |
| :---: | :---: | :---: | :---: | :---: |

| 소스 위치 | growailms-api/src/main/java/kr/go/growailms/tutor/haksa/ |
| :---- | :---- |
| **현재 상태** | TutorHaksaController.java에 11개 학사 API 엔드포인트 존재. haksa\_type\_syllabus, haksa\_is\_syllabus 필드 정의됨. 실제 학사포털 API 호출 로직 없음 (미러테이블 조회만). |
| **연관 뷰테이블** | LMS\_COURSE\_VIEW (TYPE\_SYLLABUS, IS\_SYLLABUS, CURRICULUM\_CODE, CURRICULUM\_NAME) LMS\_LECTPLAN\_VIEW (LT\_PRAC\_CTNT, LT\_ROOM\_NM, GRADE) |
| **RFP 요구사항** | SFR-005 (능동형 커리큘럼 개설 및 관리) |

**적용 과제 (5건)**

| T2.1 | KPOLY 학사시스템 REST API 연동 클라이언트 개발 (VPN 경유 Oracle DB 접근) |
| :---: | :---- |
| **T2.2** | LMS\_COURSE\_VIEW.IS\_SYLLABUS='Y'인 강좌에 대해 강의계획서 데이터 자동 매핑 |
| **T2.3** | LMS\_LECTPLAN\_VIEW 기반 주차별 강의내용(LT\_PRAC\_CTNT) 자동 반영 |
| **T2.4** | TYPE\_SYLLABUS 구분(1:일반, 2:NCS)에 따른 계획서 템플릿 분기 처리 |
| **T2.5** | 강좌 계획서 PDF 미리보기 및 다운로드 기능 구현 |

## **2.3 개설정보 불러오기**

| 상태 | ❌ 미구현 | 우선순위 | 상 | 4주 |
| :---: | :---: | :---: | :---: | :---: |

| 소스 위치 | growailms-api/.../TutorHaksaJdbcRepository.java |
| :---- | :---- |
| **현재 상태** | LM\_POLY\_COURSE 테이블에서 개설정보 조회 가능. 동기화 로그 테이블(LM\_SYNC\_LOG) 존재. 실제 배치 동기화/스케줄러 미구현. |
| **연관 뷰테이블** | LMS\_COURSE\_VIEW (전 28개 컬럼: COURSE\_CODE, COURSE\_NAME, DEPT\_NAME, OPEN\_YEAR, OPEN\_TERM, GRADE, CATEGORY, VISIBLE 등) LMS\_PROFESSOR\_VIEW (MEMBER\_KEY, COURSE\_CODE, PROF\_ORDER) LMS\_STUDENT\_VIEW (MEMBER\_KEY, COURSE\_CODE, BUNBAN\_CODE) |
| **RFP 요구사항** | SFR-005 (능동형 커리큘럼 개설 및 관리), SFR-007 (통합 인증) |

**적용 과제 (6건)**

| T3.1 | Spring Batch 기반 데이터 동기화 스케줄러 개발 (일 1회 \+ 수동 동기화) |
| :---: | :---- |
| **T3.2** | LMS\_COURSE\_VIEW 28개 컬럼 전량 매핑: TutorCourseRow와 1:1 대응 |
| **T3.3** | LMS\_PROFESSOR\_VIEW → 교수자-강좌 매핑 자동화 |
| **T3.4** | LMS\_STUDENT\_VIEW → 수강생 명부 자동 동기화 |
| **T3.5** | LM\_SYNC\_LOG 테이블 활용한 동기화 이력/오류 추적 대시보드 |
| **T3.6** | VPN 연결 상태 모니터링 및 장애 시 알림 발송 |

## **2.4 대리출석 방지**

| 상태 | ❌ 미구현 | 우선순위 | 상 | 4주 |
| :---: | :---: | :---: | :---: | :---: |

| 소스 위치 | growailms-api/src/main/java/kr/go/growailms/antifraud/ |
| :---- | :---- |
| **현재 상태** | AntiFraudService.java, AntiFraudController.java, AntiFraudRepository.java 모두 빈 클래스. IP 검증 로직은 AdminAuthenticator.java에 구현됨. |
| **연관 뷰테이블** | LMS\_MEMBER\_VIEW (MEMBER\_KEY, CAMPUS\_CODE, USER\_TYPE) LMS\_STUDENT\_VIEW (MEMBER\_KEY, COURSE\_CODE) |
| **RFP 요구사항** | SFR-001 (LLM 기반 AI 성장 에이전트 \- 보안 모듈), SER-006 (웹 보안) |

**적용 과제 (6건)**

| T4.1 | AntiFraudService 구현: 클라이언트 IP \+ User-Agent \+ 디바이스 핑거프린트 수집 |
| :---: | :---- |
| **T4.2** | 동시 접속 감지: 동일 MEMBER\_KEY로 2개 이상 세션 활성 시 차단/경고 |
| **T4.3** | 비정상 학습 패턴 탐지 알고리즘: 영상 재생속도 조작, 탭 전환 빈도, 최소 체류시간 미달 |
| **T4.4** | CAMPUS\_CODE 기반 지역 IP 대역 검증 (캠퍼스 외부 접속 시 2차 인증) |
| **T4.5** | 부정행위 로그 기록 및 관리자 알림 대시보드 |
| **T4.6** | AdminAuthenticator.java의 기존 IP 검증 로직을 AntiFraud 모듈로 통합 리팩터링 |

## **2.5 성적 등록 뷰테이블**

| 상태 | ✅ 구현완료 | 우선순위 | 하 | 1주 |
| :---: | :---: | :---: | :---: | :---: |

| 소스 위치 | demo-app/src/views/StatisticsView.vue |
| :---- | :---- |
| **현재 상태** | 과정별 상세 분석 테이블 구현 완료. 평균 진도율, 수료율, 평균 시험점수, 만족도 표시. 수료율에 따른 색상 구분(초록/노랑/빨강). |
| **연관 뷰테이블** | COURSE\_INFO\_VIEW (25개 컬럼: 총시간, 이론/실습 비율, NCS 전공교과, 교과편성총괄표 등) LMS\_COURSE\_VIEW (COURSE\_CODE, COURSE\_NAME) |
| **RFP 요구사항** | SFR-006 (직업교육 지표, 데이터 분석 및 통계) |

**적용 과제 (4건)**

| T5.1 | 현행 유지: StatisticsView.vue 정상 동작 확인 |
| :---: | :---- |
| **T5.2** | COURSE\_INFO\_VIEW 25개 컬럼 데이터 품질 검증 (빈 컬럼 확인 필요) |
| **T5.3** | 교과편성총괄표 13개 서브 테이블(NCS적용/미적용, 교양/전공/AI+x 등) 세부 연동 확인 |
| **T5.4** | 성적 등록 시 학사포털 역동기화(Write-back) API 설계 검토 |

## **2.6 과제/Q\&A 피드백 일괄 출력**

| 상태 | ✅ 구현완료 | 우선순위 | 하 | 0.5주 |
| :---: | :---: | :---: | :---: | :---: |

| 소스 위치 | project/components/CourseFeedbackReportTab.tsx |
| :---- | :---- |
| **현재 상태** | handlePrint() 함수로 인쇄 전용 HTML 생성. 과제별 묶음, 학생별 상세 정보, 피드백 포함. Q\&A 질문/답변 섹션 포함. A4 가로 인쇄 레이아웃 지원. |
| **연관 뷰테이블** | LMS\_STUDENT\_VIEW (MEMBER\_KEY, COURSE\_CODE) LMS\_MEMBER\_VIEW (KOR\_NAME, CAMPUS\_NAME) |
| **RFP 요구사항** | SFR-002 (AI 기반 질의응답 시스템) |

**적용 과제 (4건)**

| T6.1 | 현행 유지: CourseFeedbackReportTab.tsx 정상 동작 확인 |
| :---: | :---- |
| **T6.2** | LMS\_MEMBER\_VIEW의 KOR\_NAME 필드로 학생 실명 매핑 검증 |
| **T6.3** | PDF 다운로드 기능 추가 검토 (현재 브라우저 인쇄만 지원) |
| **T6.4** | 대량 데이터(50명+) 인쇄 시 성능 최적화 테스트 |

## **2.7 성적 기준 수정 불가**

| 상태 | ⚠️ 부분구현 | 우선순위 | 중 | 2주 |
| :---: | :---: | :---: | :---: | :---: |

| 소스 위치 | 교수자 LMS \- 성적관리 탭 |
| :---- | :---- |
| **현재 상태** | 현재 학사포털에서 성적 기준 데이터를 받아오지 않음. 학사포털 연동 완료 시 수정 불가 처리 예정. |
| **연관 뷰테이블** | LMS\_COURSE\_VIEW (CURRICULUM\_CODE, CURRICULUM\_NAME, GROUP\_CODE) COURSE\_INFO\_VIEW (교과구분, 학점 관련 필드) |
| **RFP 요구사항** | SFR-005 (능동형 커리큘럼 개설 및 관리) |

**적용 과제 (4건)**

| T7.1 | 학사포털 성적 기준 데이터 수신 API 개발 (CURRICULUM\_CODE 기준 매핑) |
| :---: | :---- |
| **T7.2** | 성적 기준 수신 완료 후 UI 잠금(readonly) 처리 로직 구현 |
| **T7.3** | GROUP\_CODE(U:학부/G:대학원)별 차등 성적 기준 적용 |
| **T7.4** | 성적 기준 변경 이력 추적 (감사 로그) |

## **2.8 학위/비학위 DB 일관성**

| 상태 | ⚠️ 부분구현 | 우선순위 | 중 | 3주 |
| :---: | :---: | :---: | :---: | :---: |

| 소스 위치 | 교수자 LMS \- 전체 탭 구조 |
| :---- | :---- |
| **현재 상태** | 학사/LMS 이중 관리 구조 존재 (탭 선택). TutorCourseRow에 25개 학사 필드 정의. |
| **연관 뷰테이블** | LMS\_COURSE\_VIEW (GROUP\_CODE: U=학부, G=대학원) LMS\_MEMBER\_VIEW (USER\_TYPE: 교수30, 학생 등) COURSE\_INFO\_VIEW (교육훈련과정 로드맵 포함) |
| **RFP 요구사항** | SFR-005, SFR-007 (통합 인증 체계) |

**적용 과제 (5건)**

| T8.1 | GROUP\_CODE(U/G) 기반 학위/비학위 과정 자동 분류 로직 구현 |
| :---: | :---- |
| **T8.2** | TutorCourseRow 25개 학사 필드 ↔ LMS\_COURSE\_VIEW 28개 컬럼 매핑 일관성 검증 |
| **T8.3** | USER\_TYPE별 접근 권한 분리: 학부생/대학원생/비학위 과정 수강자 |
| **T8.4** | DB 스키마 정합성 검증 스크립트 개발 및 CI/CD 파이프라인 통합 |
| **T8.5** | 학위/비학위 전환 시 데이터 무결성 보장 트랜잭션 처리 |

# **3\. 통합 구현 로드맵**

## **3.1 Phase별 추진 계획**

| 구간 | 우선 | 주요 작업 | 연관 뷰테이블 |
| :---: | :---: | ----- | ----- |
| **Phase 1 (1\~2주차)** | **상** | 개설정보 불러오기 (\#3) Spring Batch 동기화 스케줄러 VPN 모니터링 체계 | LMS\_COURSE\_VIEW LMS\_PROFESSOR\_VIEW LMS\_STUDENT\_VIEW |
| **Phase 2 (3\~4주차)** | **상** | 강좌 계획서 불러오기 (\#2) 대리출석 방지 (\#4) AntiFraud 모듈 구현 | LMS\_LECTPLAN\_VIEW LMS\_MEMBER\_VIEW |
| **Phase 3 (5\~6주차)** | **중** | 차시 유효기간 (\#1) 성적 기준 수정 불가 (\#7) 학위/비학위 DB 일관성 (\#8) | COURSE\_INFO\_VIEW LMS\_COURSE\_VIEW |
| **Phase 4 (7\~8주차)** | **하** | 성적 등록 뷰테이블 검증 (\#5) 피드백 일괄출력 최적화 (\#6) 통합 테스트 및 안정화 | 전체 8종 뷰테이블 통합 검증 |

## **3.2 RFP 요구사항 대응 현황**

| 번호 | 요구사항명 | 기능수 | 연관 분석항목 | 구현 시기 |
| :---: | ----- | :---: | ----- | :---: |
| SFR-001 | LLM 기반 AI 성장 에이전트 | 6개 기능 | \#4 대리출석 방지 (보안 모듈) | Phase 2 |
| SFR-002 | AI 기반 질의응답 시스템 | 2개 기능 | \#6 과제/Q\&A 피드백 출력 | Phase 4 |
| SFR-003 | 개인화된 커리어 정보 | 3개 기능 | 채용공고\_VIEW 27개 컬럼 연동 | 기 구현 |
| SFR-004 | 학습 추천 및 능동형 학습 | 2개 기능 | TF Recommenders 연동 | 기 구현 |
| SFR-005 | 능동형 커리큘럼 개설/관리 | 4개 기능 | \#1,\#2,\#3,\#7,\#8 (핵심 5건) | Phase 1\~3 |
| SFR-006 | 직업교육 지표/통계 | 4개 기능 | \#5 성적 등록 뷰테이블 | Phase 4 |
| SFR-007 | 통합 인증 체계 | 3개 기능 | \#3 개설정보(SSO), \#8 DB일관성 | Phase 1,3 |

# **4\. 기술 아키텍처 적용 방안**

## **4.1 데이터 동기화 아키텍처**

KPOLY 학사시스템(Oracle DB) → VPN(SecuI BlueMax 100\) → GCP Cloud SQL → GrowAI LMS 플로우에서, 8종 뷰테이블 162개 컬럼을 안정적으로 동기화하기 위한 아키텍처입니다.

| 계층 | 구성요소 | 비고 |
| ----- | ----- | ----- |
| **데이터 소스** | KPOLY Oracle DB (LM\_POLY\_COURSE 등) | VPN 경유 읽기 전용 |
| **전송 경로** | SecuI BlueMax 100 IPSec VPN | ECR-002 민간 클라우드 연계 |
| **중간 저장** | GCP Cloud SQL (미러 테이블) | LM\_SYNC\_LOG로 이력 관리 |
| **동기화 방식** | Spring Batch (일 1회 전량 \+ 변경분) | Delta 동기화 지원 |
| **프론트엔드** | Vite 6 \+ React 18 \+ Tailwind CSS v4 | 기존 데모앱 확장 |
| **API 계층** | Spring Boot REST API | TutorHaksaController 11개 EP 확장 |

## **4.2 보안 요구사항 대응**

| 요구사항 | 명칭 | 적용 방안 |
| :---: | ----- | ----- |
| **SER-001** | 개인정보 보호 | LMS\_MEMBER\_VIEW 암호화 전송, HTTPS 필수 |
| **SER-002** | 용역업체 보안 | 소스코드/IP 누출금지, VPN 접근제어 |
| **SER-006** | 웹 보안 | OWASP Top 10, 시큐어코딩, SQL Injection 방지 |
| **PER-001** | 시스템 안정성 | 15,000 동시사용자 대응, 오토스케일링 |
| **PER-002** | 데이터 보안 | AntiFraud 모듈, End-to-End 암호화 |

# **5\. 리스크 분석 및 대응 방안**

| ID | 등급 | 리스크 | 대응 방안 |
| :---: | :---: | ----- | ----- |
| **R1** | **상** | **VPN 연결 불안정** | IDC 자체 호스팅(옵션1) 검토, 이중화 VPN 구성, 800K\~1.7M원/월 비용 반영 |
| **R2** | **상** | **학사시스템 API 미제공** | 미러테이블 배치 동기화로 우회, REST API 대신 DB 직접 조회 |
| **R3** | **중** | **COURSE\_INFO\_VIEW 데이터 불완전** | 25개 컬럼 중 빈 값 다수, 학교측 데이터 입력 협조 필요 |
| **R4** | **중** | **대리출석 방지 오탐** | 단계적 적용(경고→차단), 화이트리스트 IP 관리 |
| **R5** | **하** | **성능 병목** | 15,000명 동시접속 부하테스트, GCP 오토스케일링 설정 |

# **6\. 결론 및 권고사항**

8개 분석 항목 중 미구현 3건(\#2 강좌계획서, \#3 개설정보, \#4 대리출석방지)이 전체 프로젝트 완성도에 가장 큰 영향을 미치며, 모두 SFR-005(능동형 커리큘럼) 또는 SER-006(웹 보안)과 직결됩니다. 이 3건을 Phase 1\~2(4주 이내)에 집중 투입하는 것을 권고합니다.

API 뷰테이블 8종 162개 컬럼은 GrowAI LMS의 데이터 기반을 형성하며, 특히 LMS\_COURSE\_VIEW(28컬럼)와 COURSE\_INFO\_VIEW(25컬럼, 13개 서브테이블)가 핵심 매핑 대상입니다. VPN 안정성 확보와 Spring Batch 동기화 스케줄러가 전체 로드맵의 크리티컬 패스입니다.

**총 예상 소요기간: 8주 (Phase 1\~4), 투입 인력: 백엔드 2명 \+ 프론트엔드 1명 \+ QA 1명**