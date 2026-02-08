// src/pages/instructor/lecture/PastLecturePage.tsx
// PRF-001: 과거 강의 불러오기 - 이전 학기 강의 데이터를 조회하고 현재 학기로 가져오기

import { useState } from 'react';
import { useTranslation } from '@/i18n';
import {
  History,
  BookOpen,
  Users,
  Calendar,
  Download,
  X,
  CheckCircle,
  FileText,
  Target,
  List,
  ChevronDown,
} from 'lucide-react';

// -- 타입 정의 ----------------------------------------------------------

interface PastLecture {
  id: number;
  courseName: string;
  semester: string;
  studentCount: number;
  totalWeeks: number;
  overview: string;
  objectives: string[];
  syllabus: { week: number; topic: string; method: string }[];
}

// -- Mock 데이터 -------------------------------------------------------

const pastLectures: PastLecture[] = [
  {
    id: 1,
    courseName: '파이썬 프로그래밍 기초',
    semester: '2025-1학기',
    studentCount: 38,
    totalWeeks: 15,
    overview:
      '파이썬 언어의 기본 문법과 활용법을 학습하며, 실무 프로젝트를 통해 프로그래밍 역량을 강화합니다. 데이터 처리, 웹 크롤링 등 실용적인 주제를 다룹니다.',
    objectives: [
      '파이썬 기본 문법을 이해하고 활용할 수 있다',
      '조건문, 반복문, 함수를 활용한 프로그래밍이 가능하다',
      '라이브러리를 활용한 데이터 처리를 수행할 수 있다',
      '간단한 웹 크롤링 프로젝트를 완성할 수 있다',
    ],
    syllabus: [
      { week: 1, topic: '파이썬 소개 및 개발환경 설정', method: '이론+실습' },
      { week: 2, topic: '변수와 자료형', method: '이론+실습' },
      { week: 3, topic: '조건문과 반복문', method: '이론+실습' },
      { week: 4, topic: '함수와 모듈', method: '이론+실습' },
      { week: 5, topic: '리스트와 딕셔너리', method: '실습 중심' },
    ],
  },
  {
    id: 2,
    courseName: '데이터베이스 설계 및 실습',
    semester: '2025-1학기',
    studentCount: 32,
    totalWeeks: 15,
    overview:
      '관계형 데이터베이스의 설계 원리와 SQL 활용법을 학습합니다. ER 모델링부터 정규화, 성능 최적화까지 실무 중심으로 교육합니다.',
    objectives: [
      'ER 다이어그램을 설계할 수 있다',
      'SQL DDL/DML을 능숙하게 사용할 수 있다',
      '정규화 이론을 이해하고 적용할 수 있다',
      '인덱스 설계와 쿼리 최적화를 수행할 수 있다',
    ],
    syllabus: [
      { week: 1, topic: '데이터베이스 개요', method: '이론' },
      { week: 2, topic: 'ER 모델링', method: '이론+실습' },
      { week: 3, topic: '관계형 모델', method: '이론' },
      { week: 4, topic: 'SQL 기초 (DDL)', method: '실습 중심' },
      { week: 5, topic: 'SQL 활용 (DML)', method: '실습 중심' },
    ],
  },
  {
    id: 3,
    courseName: '웹 프로그래밍 실무',
    semester: '2024-2학기',
    studentCount: 40,
    totalWeeks: 15,
    overview:
      'HTML, CSS, JavaScript를 기반으로 웹 프론트엔드 개발 역량을 키우고, React 프레임워크를 활용한 SPA 개발 방법을 학습합니다.',
    objectives: [
      'HTML5/CSS3으로 반응형 웹페이지를 제작할 수 있다',
      'JavaScript ES6+ 문법을 활용할 수 있다',
      'React 컴포넌트 기반 개발이 가능하다',
      'REST API와 연동하는 웹 앱을 완성할 수 있다',
    ],
    syllabus: [
      { week: 1, topic: 'HTML5 기초와 시맨틱 태그', method: '이론+실습' },
      { week: 2, topic: 'CSS3와 Flexbox/Grid', method: '실습 중심' },
      { week: 3, topic: 'JavaScript 기초', method: '이론+실습' },
      { week: 4, topic: 'DOM 조작과 이벤트', method: '실습 중심' },
      { week: 5, topic: 'ES6+ 고급 문법', method: '이론+실습' },
    ],
  },
  {
    id: 4,
    courseName: '인공지능 기초',
    semester: '2024-2학기',
    studentCount: 28,
    totalWeeks: 15,
    overview:
      '머신러닝과 딥러닝의 기초 이론을 학습하고, Python 기반 라이브러리를 활용한 실습을 통해 AI 모델 개발 역량을 배양합니다.',
    objectives: [
      '머신러닝의 기본 개념과 학습 방법을 이해한다',
      'scikit-learn으로 분류/회귀 모델을 구현할 수 있다',
      'TensorFlow/Keras로 간단한 신경망을 구축할 수 있다',
      'AI 프로젝트의 전체 파이프라인을 수행할 수 있다',
    ],
    syllabus: [
      { week: 1, topic: '인공지능 개요 및 역사', method: '이론' },
      { week: 2, topic: '머신러닝 기초 (지도/비지도학습)', method: '이론' },
      { week: 3, topic: '데이터 전처리와 특징 공학', method: '이론+실습' },
      { week: 4, topic: '선형회귀와 로지스틱회귀', method: '실습 중심' },
      { week: 5, topic: '의사결정트리와 랜덤포레스트', method: '실습 중심' },
    ],
  },
  {
    id: 5,
    courseName: '네트워크 보안',
    semester: '2024-1학기',
    studentCount: 25,
    totalWeeks: 15,
    overview:
      '네트워크 보안의 핵심 개념과 실무 기술을 학습합니다. 암호학, 방화벽 설정, 침입 탐지 등 보안 운영 실무를 다룹니다.',
    objectives: [
      '네트워크 보안 위협과 대응 방법을 이해한다',
      '대칭/비대칭 암호화 원리를 설명할 수 있다',
      '방화벽 정책을 설계하고 적용할 수 있다',
      '침입 탐지 시스템을 설정하고 로그를 분석할 수 있다',
    ],
    syllabus: [
      { week: 1, topic: '네트워크 보안 개요', method: '이론' },
      { week: 2, topic: '암호학 기초', method: '이론' },
      { week: 3, topic: '대칭키/공개키 암호화', method: '이론+실습' },
      { week: 4, topic: 'PKI와 디지털 인증서', method: '이론+실습' },
      { week: 5, topic: '방화벽 구성 및 운영', method: '실습 중심' },
    ],
  },
];

const semesters = ['전체', '2025-1학기', '2024-2학기', '2024-1학기'];

// -- 메인 컴포넌트 -------------------------------------------------------

export default function PastLecturePage() {
  const { t } = useTranslation();
  const [selectedSemester, setSelectedSemester] = useState('전체');
  const [selectedLecture, setSelectedLecture] = useState<PastLecture | null>(null);
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [importedIds, setImportedIds] = useState<number[]>([]);

  const filteredLectures =
    selectedSemester === '전체'
      ? pastLectures
      : pastLectures.filter((l) => l.semester === selectedSemester);

  const handleImportClick = (lecture: PastLecture) => {
    setSelectedLecture(lecture);
  };

  const handleConfirmImport = () => {
    if (selectedLecture) {
      setImportedIds((prev) => [...prev, selectedLecture.id]);
      setShowConfirmModal(true);
    }
  };

  const handleCloseConfirm = () => {
    setShowConfirmModal(false);
    setSelectedLecture(null);
  };

  return (
    <div className="space-y-6">
      {/* 페이지 헤더 */}
      <div>
        <div className="flex items-center gap-3 mb-1">
          <div className="w-10 h-10 rounded-xl bg-indigo-100 dark:bg-indigo-900/30 flex items-center justify-center">
            <History className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
              {t('instructor.pastLecturesTitle')}
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              {t('instructor.pastLecturesDesc')}
            </p>
          </div>
        </div>
      </div>

      {/* 학기 선택 필터 */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-4">
        <div className="flex items-center gap-3">
          <Calendar className="w-4 h-4 text-gray-500" />
          <span className="text-sm font-medium text-gray-700 dark:text-gray-300">학기 선택</span>
          <div className="relative">
            <select
              value={selectedSemester}
              onChange={(e) => setSelectedSemester(e.target.value)}
              className="appearance-none rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 pl-4 pr-10 py-2 text-sm text-gray-900 dark:text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-colors"
            >
              {semesters.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
            <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
          </div>
          <span className="text-sm text-gray-400 dark:text-gray-500">
            총 {filteredLectures.length}개 강의
          </span>
        </div>
      </div>

      {/* 강의 목록 + 상세 패널 */}
      <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
        {/* 왼쪽: 강의 목록 */}
        <div className="lg:col-span-2 space-y-3">
          {filteredLectures.map((lecture) => (
            <div
              key={lecture.id}
              onClick={() => handleImportClick(lecture)}
              className={`bg-white dark:bg-gray-800 rounded-xl p-5 shadow-sm border cursor-pointer transition-all hover:shadow-md ${
                selectedLecture?.id === lecture.id
                  ? 'border-blue-500 ring-1 ring-blue-500'
                  : 'border-gray-100 dark:border-gray-700'
              }`}
            >
              <div className="flex items-start justify-between mb-3">
                <div>
                  <h3 className="text-sm font-semibold text-gray-900 dark:text-white">
                    {lecture.courseName}
                  </h3>
                  <span className="mt-1 inline-block px-2 py-0.5 text-xs font-medium rounded-full bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400">
                    {lecture.semester}
                  </span>
                </div>
                {importedIds.includes(lecture.id) ? (
                  <span className="flex items-center gap-1 text-xs text-emerald-600 dark:text-emerald-400 font-medium">
                    <CheckCircle className="w-4 h-4" />
                    불러오기 완료
                  </span>
                ) : (
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      handleImportClick(lecture);
                    }}
                    className="flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-blue-600 hover:text-blue-700 bg-blue-50 hover:bg-blue-100 dark:bg-blue-900/20 dark:text-blue-400 dark:hover:bg-blue-900/40 rounded-lg transition-colors"
                  >
                    <Download className="w-3.5 h-3.5" />
                    불러오기
                  </button>
                )}
              </div>
              <div className="flex items-center gap-4 text-xs text-gray-500 dark:text-gray-400">
                <span className="flex items-center gap-1">
                  <Users className="w-3.5 h-3.5" />
                  수강생 {lecture.studentCount}명
                </span>
                <span className="flex items-center gap-1">
                  <BookOpen className="w-3.5 h-3.5" />
                  {lecture.totalWeeks}주차
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* 오른쪽: 상세 메타데이터 */}
        <div className="lg:col-span-3">
          {selectedLecture ? (
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 space-y-6 sticky top-6">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-bold text-gray-900 dark:text-white">
                  {selectedLecture.courseName}
                </h2>
                <span className="px-3 py-1 text-xs font-medium rounded-full bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-400">
                  {selectedLecture.semester}
                </span>
              </div>

              {/* 개요 */}
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <FileText className="w-4 h-4 text-gray-500" />
                  <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300">과목 개요</h3>
                </div>
                <p className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                  {selectedLecture.overview}
                </p>
              </div>

              {/* 학습 목표 */}
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <Target className="w-4 h-4 text-gray-500" />
                  <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300">학습 목표</h3>
                </div>
                <ul className="space-y-1.5">
                  {selectedLecture.objectives.map((obj, i) => (
                    <li key={i} className="flex items-start gap-2 text-sm text-gray-600 dark:text-gray-400">
                      <CheckCircle className="w-4 h-4 text-green-500 mt-0.5 shrink-0" />
                      {obj}
                    </li>
                  ))}
                </ul>
              </div>

              {/* 실라버스 미리보기 */}
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <List className="w-4 h-4 text-gray-500" />
                  <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300">
                    실라버스 미리보기 (상위 5주차)
                  </h3>
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-gray-200 dark:border-gray-700">
                        <th className="text-left py-2 px-3 text-xs font-semibold text-gray-500 dark:text-gray-400">
                          주차
                        </th>
                        <th className="text-left py-2 px-3 text-xs font-semibold text-gray-500 dark:text-gray-400">
                          학습주제
                        </th>
                        <th className="text-left py-2 px-3 text-xs font-semibold text-gray-500 dark:text-gray-400">
                          교수방법
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {selectedLecture.syllabus.map((row) => (
                        <tr
                          key={row.week}
                          className="border-b border-gray-100 dark:border-gray-700/50"
                        >
                          <td className="py-2 px-3 text-gray-700 dark:text-gray-300 font-medium">
                            {row.week}주차
                          </td>
                          <td className="py-2 px-3 text-gray-600 dark:text-gray-400">{row.topic}</td>
                          <td className="py-2 px-3">
                            <span className="px-2 py-0.5 text-xs rounded-full bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400">
                              {row.method}
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* 불러오기 버튼 */}
              {!importedIds.includes(selectedLecture.id) && (
                <button
                  onClick={handleConfirmImport}
                  className="w-full flex items-center justify-center gap-2 px-4 py-3 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors shadow-sm"
                >
                  <Download className="w-4 h-4" />
                  현재 학기로 불러오기
                </button>
              )}
              {importedIds.includes(selectedLecture.id) && (
                <div className="flex items-center justify-center gap-2 px-4 py-3 text-sm font-medium text-emerald-600 bg-emerald-50 dark:bg-emerald-900/20 dark:text-emerald-400 rounded-lg">
                  <CheckCircle className="w-4 h-4" />
                  이미 불러오기 완료된 강의입니다
                </div>
              )}
            </div>
          ) : (
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-12 flex flex-col items-center justify-center text-center">
              <History className="w-16 h-16 text-gray-300 dark:text-gray-600 mb-4" />
              <p className="text-sm text-gray-500 dark:text-gray-400 mb-1">
                왼쪽 목록에서 강의를 선택하세요
              </p>
              <p className="text-xs text-gray-400 dark:text-gray-500">
                과목 개요, 학습 목표, 실라버스를 확인할 수 있습니다
              </p>
            </div>
          )}
        </div>
      </div>

      {/* 불러오기 확인 모달 */}
      {showConfirmModal && selectedLecture && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="absolute inset-0 bg-black/50"
            onClick={handleCloseConfirm}
          />
          <div className="relative bg-white dark:bg-gray-800 rounded-2xl shadow-2xl max-w-md w-full p-6 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">불러오기 완료</h3>
              <button
                onClick={handleCloseConfirm}
                className="p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <X className="w-5 h-5 text-gray-400" />
              </button>
            </div>
            <div className="flex items-center gap-3 p-4 bg-emerald-50 dark:bg-emerald-900/20 rounded-xl">
              <CheckCircle className="w-10 h-10 text-emerald-500 shrink-0" />
              <div>
                <p className="text-sm font-semibold text-gray-900 dark:text-white">
                  {selectedLecture.courseName}
                </p>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                  {selectedLecture.semester} 강의 데이터를 현재 학기로 성공적으로 불러왔습니다.
                </p>
              </div>
            </div>
            <div className="text-xs text-gray-500 dark:text-gray-400 space-y-1">
              <p>가져온 항목:</p>
              <ul className="list-disc list-inside space-y-0.5 text-gray-600 dark:text-gray-400">
                <li>과목 기본정보 및 개요</li>
                <li>학습 목표 ({selectedLecture.objectives.length}개)</li>
                <li>주차별 실라버스 ({selectedLecture.totalWeeks}주차)</li>
                <li>교수방법 및 비고사항</li>
              </ul>
            </div>
            <div className="flex gap-3">
              <button
                onClick={handleCloseConfirm}
                className="flex-1 px-4 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors"
              >
                {t('common.close')}
              </button>
              <button
                onClick={handleCloseConfirm}
                className="flex-1 px-4 py-2.5 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors"
              >
                실라버스 수정하기
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
