// pages/student/competency/CompetencyTagPage.tsx — STD-002: 역량 태그 클라우드
import { useState } from 'react';
import { Tags, Info, X, BookOpen, Award, Brain, Filter } from 'lucide-react';
import { useTranslation } from '@/i18n';

// --- 역량 태그 Mock Data ---
type TagCategory = 'SKILL' | 'CERT' | 'NCS' | 'TOOL';
type TagSource = '과목이수' | '자격증' | 'AI분석';

interface CompetencyTag {
  id: number;
  name: string;
  category: TagCategory;
  proficiency: number; // 1~100 숙련도
  source: TagSource;
  ncsCode?: string;
  ncsDescription?: string;
}

const mockTags: CompetencyTag[] = [
  { id: 1, name: 'Java', category: 'SKILL', proficiency: 85, source: '과목이수', ncsCode: '20010101', ncsDescription: '응용SW엔지니어링 - Java 언어를 활용한 소프트웨어 개발 능력' },
  { id: 2, name: 'Python', category: 'SKILL', proficiency: 90, source: '과목이수', ncsCode: '20010102', ncsDescription: '응용SW엔지니어링 - Python 언어를 활용한 데이터 처리 및 자동화' },
  { id: 3, name: 'SQL', category: 'SKILL', proficiency: 78, source: '과목이수', ncsCode: '20010203', ncsDescription: 'DB엔지니어링 - 데이터베이스 설계 및 SQL 쿼리 작성 능력' },
  { id: 4, name: 'CAD', category: 'TOOL', proficiency: 60, source: '과목이수', ncsCode: '15020101', ncsDescription: '기계설계 - CAD 도구를 활용한 기계 도면 설계' },
  { id: 5, name: '용접', category: 'SKILL', proficiency: 55, source: '과목이수', ncsCode: '15030201', ncsDescription: '금속가공 - 아크용접, 가스용접 등 금속 접합 기술' },
  { id: 6, name: '전기', category: 'SKILL', proficiency: 70, source: '과목이수', ncsCode: '19010101', ncsDescription: '전력설비운영 - 전기설비 설치 및 운영 관리 기술' },
  { id: 7, name: '데이터분석', category: 'SKILL', proficiency: 82, source: 'AI분석', ncsCode: '20010301', ncsDescription: '데이터분석 - 데이터 수집, 전처리, 분석 및 시각화' },
  { id: 8, name: '클라우드', category: 'SKILL', proficiency: 65, source: 'AI분석', ncsCode: '20010402', ncsDescription: '클라우드엔지니어링 - AWS/GCP 등 클라우드 인프라 관리' },
  { id: 9, name: '정보처리기사', category: 'CERT', proficiency: 95, source: '자격증', ncsCode: '20010100', ncsDescription: '정보기술 전반 - 소프트웨어 개발, DB, 네트워크, 보안 등 종합 역량' },
  { id: 10, name: 'SQLD', category: 'CERT', proficiency: 88, source: '자격증', ncsCode: '20010203', ncsDescription: 'DB엔지니어링 - SQL 개발자 자격으로 DB 설계 및 쿼리 역량 인증' },
  { id: 11, name: 'React', category: 'SKILL', proficiency: 72, source: '과목이수', ncsCode: '20010103', ncsDescription: 'UI/UX엔지니어링 - React 프레임워크를 활용한 프론트엔드 개발' },
  { id: 12, name: 'Docker', category: 'TOOL', proficiency: 58, source: 'AI분석', ncsCode: '20010401', ncsDescription: 'IT시스템관리 - Docker 컨테이너 기반 서비스 배포 관리' },
  { id: 13, name: 'Spring Boot', category: 'SKILL', proficiency: 80, source: '과목이수', ncsCode: '20010101', ncsDescription: '응용SW엔지니어링 - Spring Boot 프레임워크 기반 백엔드 개발' },
  { id: 14, name: '네트워크관리', category: 'NCS', proficiency: 50, source: 'AI분석', ncsCode: '20010301', ncsDescription: '네트워크엔지니어링 - 네트워크 구축 및 운영 관리 기술' },
  { id: 15, name: 'Git', category: 'TOOL', proficiency: 88, source: '과목이수', ncsCode: '20010100', ncsDescription: 'SW개발관리 - Git 버전관리 시스템 활용 역량' },
  { id: 16, name: '머신러닝', category: 'SKILL', proficiency: 68, source: '과목이수', ncsCode: '20010302', ncsDescription: '인공지능엔지니어링 - 머신러닝 모델 학습 및 배포 역량' },
  { id: 17, name: 'Linux', category: 'TOOL', proficiency: 62, source: 'AI분석', ncsCode: '20010401', ncsDescription: 'IT시스템관리 - Linux 서버 운영 및 관리 기술' },
  { id: 18, name: '전기기능사', category: 'CERT', proficiency: 75, source: '자격증', ncsCode: '19010100', ncsDescription: '전기 설비 - 전기설비의 시공 및 유지보수 역량 인증' },
];

// 카테고리별 색상 설정
const categoryColors: Record<TagCategory, { bg: string; text: string; border: string; label: string }> = {
  SKILL: { bg: 'bg-blue-50 dark:bg-blue-900/20', text: 'text-blue-700 dark:text-blue-400', border: 'border-blue-200 dark:border-blue-800', label: '기술' },
  CERT:  { bg: 'bg-green-50 dark:bg-green-900/20', text: 'text-green-700 dark:text-green-400', border: 'border-green-200 dark:border-green-800', label: '자격증' },
  NCS:   { bg: 'bg-purple-50 dark:bg-purple-900/20', text: 'text-purple-700 dark:text-purple-400', border: 'border-purple-200 dark:border-purple-800', label: 'NCS' },
  TOOL:  { bg: 'bg-orange-50 dark:bg-orange-900/20', text: 'text-orange-700 dark:text-orange-400', border: 'border-orange-200 dark:border-orange-800', label: '도구' },
};

const sourceIcons: Record<TagSource, typeof BookOpen> = {
  '과목이수': BookOpen,
  '자격증': Award,
  'AI분석': Brain,
};

// 숙련도에 따른 태그 크기 계산
function getTagSize(proficiency: number): string {
  if (proficiency >= 90) return 'text-xl px-4 py-2.5';
  if (proficiency >= 80) return 'text-lg px-3.5 py-2';
  if (proficiency >= 70) return 'text-base px-3 py-1.5';
  if (proficiency >= 60) return 'text-sm px-2.5 py-1.5';
  return 'text-xs px-2 py-1';
}

export default function CompetencyTagPage() {
  const { t } = useTranslation();
  const [selectedTag, setSelectedTag] = useState<CompetencyTag | null>(null);
  const [filterCategory, setFilterCategory] = useState<TagCategory | 'ALL'>('ALL');
  const [filterSource, setFilterSource] = useState<TagSource | 'ALL'>('ALL');

  const filtered = mockTags.filter((tag) => {
    const matchCat = filterCategory === 'ALL' || tag.category === filterCategory;
    const matchSrc = filterSource === 'ALL' || tag.source === filterSource;
    return matchCat && matchSrc;
  });

  const totalTags = mockTags.length;
  const avgProficiency = Math.round(mockTags.reduce((sum, t) => sum + t.proficiency, 0) / totalTags);

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('student.competencyTitle')}</h1>
          <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">
            {t('student.competencyDesc')}
          </p>
        </div>
      </div>

      {/* 카테고리 범례 + 필터 */}
      <div className="card p-4">
        <div className="flex flex-col sm:flex-row sm:items-center gap-4">
          <div className="flex items-center gap-1.5 text-xs text-gray-500">
            <Filter className="w-3.5 h-3.5" />
            <span>카테고리:</span>
          </div>
          <div className="filter-bar">
            <button
              onClick={() => setFilterCategory('ALL')}
              className={`filter-chip ${filterCategory === 'ALL' ? 'filter-chip-active' : 'filter-chip-inactive'}`}
            >
              전체
            </button>
            {(Object.keys(categoryColors) as TagCategory[]).map((cat) => (
              <button
                key={cat}
                onClick={() => setFilterCategory(cat)}
                className={`filter-chip ${filterCategory === cat ? 'filter-chip-active' : 'filter-chip-inactive'}`}
              >
                <span className={`w-2 h-2 rounded-full ${categoryColors[cat].bg} border ${categoryColors[cat].border}`} />
                {categoryColors[cat].label} ({cat})
              </button>
            ))}
          </div>
        </div>
        <div className="flex flex-col sm:flex-row sm:items-center gap-4 mt-3 pt-3 border-t border-gray-100 dark:border-slate-800">
          <div className="flex items-center gap-1.5 text-xs text-gray-500">
            <Info className="w-3.5 h-3.5" />
            <span>출처:</span>
          </div>
          <div className="filter-bar">
            <button
              onClick={() => setFilterSource('ALL')}
              className={`filter-chip ${filterSource === 'ALL' ? 'filter-chip-active' : 'filter-chip-inactive'}`}
            >
              전체
            </button>
            {(['과목이수', '자격증', 'AI분석'] as TagSource[]).map((src) => {
              const Icon = sourceIcons[src];
              return (
                <button
                  key={src}
                  onClick={() => setFilterSource(src)}
                  className={`filter-chip ${filterSource === src ? 'filter-chip-active' : 'filter-chip-inactive'}`}
                >
                  <Icon className="w-3 h-3" />
                  {src}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* 태그 클라우드 */}
      <div className="card p-6">
        <div className="flex items-center gap-2 mb-4">
          <Tags className="w-4 h-4 text-primary-600" />
          <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">보유 역량 태그</h2>
        </div>
        <div className="flex flex-wrap gap-3 justify-center items-center min-h-[200px]">
          {filtered.map((tag) => {
            const colors = categoryColors[tag.category];
            const size = getTagSize(tag.proficiency);
            return (
              <button
                key={tag.id}
                onClick={() => setSelectedTag(tag)}
                className={`${colors.bg} ${colors.text} border ${colors.border} rounded-full font-medium
                  ${size} hover:shadow-md hover:scale-105 transition-all cursor-pointer
                  flex items-center gap-1.5`}
                title={`${tag.name} (숙련도: ${tag.proficiency}%)`}
              >
                <span>#</span>
                <span>{tag.name}</span>
                <span className="text-[10px] opacity-60">{tag.proficiency}%</span>
              </button>
            );
          })}
          {filtered.length === 0 && (
            <p className="text-sm text-gray-400">해당 필터에 맞는 태그가 없습니다.</p>
          )}
        </div>
        <div className="flex items-center justify-center gap-4 mt-4 pt-3 border-t border-gray-100 dark:border-slate-800">
          <span className="text-[10px] text-gray-400">태그 크기 = 숙련도 수준</span>
          <span className="text-[10px] text-gray-300 dark:text-slate-600">|</span>
          <span className="text-[10px] text-gray-400">태그 클릭 시 NCS 직무 설명 확인</span>
        </div>
      </div>

      {/* 역량 요약 테이블 */}
      <div className="card p-5 space-y-4">
        <h2 className="text-sm font-semibold text-gray-700 dark:text-slate-300">역량 상세 목록</h2>
        <div className="table-container">
          <table className="w-full">
            <thead className="table-head">
              <tr>
                <th className="table-th">역량명</th>
                <th className="table-th-center">카테고리</th>
                <th className="table-th-center">숙련도</th>
                <th className="table-th-center">출처</th>
                <th className="table-th-center">NCS 코드</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((tag) => {
                const colors = categoryColors[tag.category];
                const SourceIcon = sourceIcons[tag.source];
                return (
                  <tr
                    key={tag.id}
                    className="table-row cursor-pointer hover:bg-gray-50 dark:hover:bg-slate-800"
                    onClick={() => setSelectedTag(tag)}
                  >
                    <td className="table-td font-medium">#{tag.name}</td>
                    <td className="table-td-center">
                      <span className={`badge-sm ${colors.bg} ${colors.text} border ${colors.border}`}>
                        {categoryColors[tag.category].label}
                      </span>
                    </td>
                    <td className="table-td-center">
                      <div className="flex items-center gap-2">
                        <div className="w-16 h-1.5 bg-gray-100 dark:bg-slate-700 rounded-full overflow-hidden">
                          <div
                            className={`h-full rounded-full ${tag.proficiency >= 80 ? 'bg-success-500' : tag.proficiency >= 60 ? 'bg-primary-500' : 'bg-warning-500'}`}
                            style={{ width: `${tag.proficiency}%` }}
                          />
                        </div>
                        <span className="text-[10px]">{tag.proficiency}%</span>
                      </div>
                    </td>
                    <td className="table-td-center">
                      <span className="flex items-center justify-center gap-1 text-[10px]">
                        <SourceIcon className="w-3 h-3" />
                        {tag.source}
                      </span>
                    </td>
                    <td className="table-td-center text-[10px] text-gray-400">{tag.ncsCode}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* NCS 직무 설명 팝업 */}
      {selectedTag && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="card max-w-md w-full p-6 space-y-4 shadow-xl">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Tags className="w-5 h-5 text-primary-600" />
                <h3 className="text-base font-semibold text-gray-900 dark:text-white">#{selectedTag.name}</h3>
              </div>
              <button onClick={() => setSelectedTag(null)} className="p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800">
                <X className="w-4 h-4 text-gray-400" />
              </button>
            </div>
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <span className={`badge-sm ${categoryColors[selectedTag.category].bg} ${categoryColors[selectedTag.category].text} border ${categoryColors[selectedTag.category].border}`}>
                  {categoryColors[selectedTag.category].label}
                </span>
                <span className="text-xs text-gray-500">NCS {selectedTag.ncsCode}</span>
              </div>
              <div className="p-3 bg-surface-muted dark:bg-slate-800 rounded-lg">
                <p className="text-sm text-gray-700 dark:text-slate-300 leading-relaxed">
                  {selectedTag.ncsDescription}
                </p>
              </div>
              <div className="grid grid-cols-2 gap-3 text-xs">
                <div className="p-2 bg-gray-50 dark:bg-slate-800 rounded-lg text-center">
                  <div className="text-gray-500">숙련도</div>
                  <div className="text-lg font-bold text-primary-600 mt-0.5">{selectedTag.proficiency}%</div>
                </div>
                <div className="p-2 bg-gray-50 dark:bg-slate-800 rounded-lg text-center">
                  <div className="text-gray-500">획득 출처</div>
                  <div className="text-sm font-medium text-gray-900 dark:text-white mt-1 flex items-center justify-center gap-1">
                    {(() => { const Icon = sourceIcons[selectedTag.source]; return <Icon className="w-3.5 h-3.5" />; })()}
                    {selectedTag.source}
                  </div>
                </div>
              </div>
            </div>
            <button onClick={() => setSelectedTag(null)} className="btn-primary w-full text-sm">닫기</button>
          </div>
        </div>
      )}
    </div>
  );
}
