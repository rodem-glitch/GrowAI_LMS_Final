// pages/haksa/CalendarPage.tsx -- 학사 일정
import { useState, useMemo } from 'react';
import { ChevronLeft, ChevronRight, Calendar, X, MapPin, Clock } from 'lucide-react';
import { useTranslation } from '@/i18n';

interface AcademicEvent {
  id: number;
  date: string;
  endDate?: string;
  title: string;
  category: '수업' | '시험' | '행사' | '방학';
  description?: string;
  location?: string;
  time?: string;
}

const allEvents: AcademicEvent[] = [
  // 1월
  { id: 1, date: '2026-01-05', title: '겨울방학 특별 보충수업', category: '수업', description: '겨울방학 중 보충수업 운영 (1/5~1/16)', location: '각 학과 강의실', time: '09:00~12:00' },
  { id: 2, date: '2026-01-15', title: '성적 최종 확정', category: '수업', description: '2025학년도 2학기 성적 최종 확정일', time: '18:00 마감' },
  { id: 3, date: '2026-01-20', title: '졸업 사정회', category: '행사', description: '2025학년도 졸업 사정 심사', location: '본관 대회의실' },
  // 2월
  { id: 4, date: '2026-02-02', title: '2학기 개강', category: '수업', description: '2026학년도 2학기 정규 수업 시작', location: '각 학과 강의실', time: '09:00' },
  { id: 5, date: '2026-02-10', endDate: '2026-02-14', title: '수강 변경 기간', category: '수업', description: '수강 신청 변경 및 취소 가능 기간 (2/10~2/14)', time: '09:00~17:00' },
  { id: 6, date: '2026-02-14', title: '졸업식', category: '행사', description: '2025학년도 전기 졸업식', location: '대강당', time: '10:00' },
  { id: 7, date: '2026-02-17', title: '학과 OT 행사', category: '행사', description: '각 학과별 오리엔테이션 진행', location: '각 학과 세미나실', time: '14:00~16:00' },
  { id: 8, date: '2026-02-25', title: '신입생 환영회', category: '행사', description: '2026학년도 신입생 환영 행사', location: '학생회관', time: '15:00' },
  // 3월
  { id: 9, date: '2026-03-02', title: '1학기 개강', category: '수업', description: '2026학년도 1학기 정규 수업 시작', location: '각 학과 강의실', time: '09:00' },
  { id: 10, date: '2026-03-09', endDate: '2026-03-13', title: '수강 정정 기간', category: '수업', description: '수강 신청 정정 기간 (3/9~3/13)' },
  { id: 11, date: '2026-03-15', endDate: '2026-03-22', title: '중간고사 기간', category: '시험', description: '중간고사 시작 (3/15~3/22)', time: '시간표에 따름' },
  { id: 12, date: '2026-03-22', title: '중간고사 종료', category: '시험', description: '중간고사 마지막 날' },
  // 4월
  { id: 13, date: '2026-04-05', title: '체육대회', category: '행사', description: '전교생 참여 체육대회', location: '운동장', time: '09:00~17:00' },
  { id: 14, date: '2026-04-10', title: '취업 박람회', category: '행사', description: '2026 상반기 취업 박람회', location: '체육관', time: '10:00~16:00' },
  { id: 15, date: '2026-04-15', title: '중간 성적 입력 마감', category: '수업', description: '중간고사 성적 입력 마감일', time: '23:59' },
  { id: 16, date: '2026-04-20', endDate: '2026-04-24', title: '현장실습 기간', category: '수업', description: '산학협력 현장실습 주간' },
  // 5월
  { id: 17, date: '2026-05-05', title: '어린이날 휴강', category: '방학', description: '법정 공휴일 휴강' },
  { id: 18, date: '2026-05-10', endDate: '2026-05-17', title: '기말고사 기간', category: '시험', description: '기말고사 시작 (5/10~5/17)', time: '시간표에 따름' },
  { id: 19, date: '2026-05-19', title: '부처님오신날 휴강', category: '방학', description: '법정 공휴일 휴강' },
  { id: 20, date: '2026-05-25', title: '학과 MT', category: '행사', description: '각 학과별 MT 일정', location: '외부' },
  // 6월
  { id: 21, date: '2026-06-01', title: '여름방학 시작', category: '방학', description: '2026학년도 여름방학 시작' },
  { id: 22, date: '2026-06-06', title: '현충일', category: '방학', description: '법정 공휴일' },
  { id: 23, date: '2026-06-15', endDate: '2026-06-26', title: '계절학기 수강 신청', category: '수업', description: '여름 계절학기 수강 신청 기간' },
  // 7월
  { id: 24, date: '2026-07-01', endDate: '2026-07-24', title: '여름 계절학기', category: '수업', description: '여름 계절학기 수업 기간', location: '각 강의실' },
  { id: 25, date: '2026-07-15', title: '하계 캠프', category: '행사', description: '리더십 하계 캠프', location: '연수원', time: '2박 3일' },
  // 8월
  { id: 26, date: '2026-08-15', title: '광복절', category: '방학', description: '법정 공휴일' },
  { id: 27, date: '2026-08-20', endDate: '2026-08-28', title: '2학기 수강 신청', category: '수업', description: '2학기 수강 신청 기간' },
  { id: 28, date: '2026-08-25', title: '여름방학 종료', category: '방학', description: '2026학년도 여름방학 마지막 날' },
  // 9월
  { id: 29, date: '2026-09-01', title: '2학기 개강', category: '수업', description: '2026학년도 2학기 정규 수업 시작', location: '각 학과 강의실' },
  { id: 30, date: '2026-09-10', title: '추석 연휴', category: '방학', description: '추석 연휴 휴강 (9/10~9/12)' },
  // 10월
  { id: 31, date: '2026-10-09', title: '한글날 휴강', category: '방학', description: '법정 공휴일 휴강' },
  { id: 32, date: '2026-10-15', endDate: '2026-10-22', title: '2학기 중간고사', category: '시험', description: '2학기 중간고사 기간' },
  { id: 33, date: '2026-10-25', title: '축제', category: '행사', description: '대학 축제 주간', location: '캠퍼스 전역', time: '종일' },
  // 11월
  { id: 34, date: '2026-11-10', title: '수능일 휴강', category: '방학', description: '대학수학능력시험일 휴강' },
  { id: 35, date: '2026-11-20', title: '취업 특강', category: '행사', description: '졸업생 대상 취업 특강', location: '대강당', time: '14:00' },
  // 12월
  { id: 36, date: '2026-12-07', endDate: '2026-12-14', title: '2학기 기말고사', category: '시험', description: '2학기 기말고사 기간' },
  { id: 37, date: '2026-12-20', title: '겨울방학 시작', category: '방학', description: '2026학년도 겨울방학 시작' },
  { id: 38, date: '2026-12-25', title: '성탄절', category: '방학', description: '법정 공휴일' },
];

const categoryStyles: Record<string, { badge: string; dot: string }> = {
  '수업': {
    badge: 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
    dot: 'bg-blue-500',
  },
  '시험': {
    badge: 'bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-400',
    dot: 'bg-red-500',
  },
  '행사': {
    badge: 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400',
    dot: 'bg-green-500',
  },
  '방학': {
    badge: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-400',
    dot: 'bg-gray-500',
  },
};

export default function CalendarPage() {
  const { t } = useTranslation();
  const now = new Date();
  const [currentMonth, setCurrentMonth] = useState({ year: now.getFullYear(), month: now.getMonth() + 1 });
  const [selectedCategories, setSelectedCategories] = useState<Set<string>>(new Set(['수업', '시험', '행사', '방학']));
  const [selectedEvent, setSelectedEvent] = useState<AcademicEvent | null>(null);

  const handlePrev = () => {
    setCurrentMonth((prev) => {
      if (prev.month === 1) return { year: prev.year - 1, month: 12 };
      return { ...prev, month: prev.month - 1 };
    });
  };

  const handleNext = () => {
    setCurrentMonth((prev) => {
      if (prev.month === 12) return { year: prev.year + 1, month: 1 };
      return { ...prev, month: prev.month + 1 };
    });
  };

  const handleToday = () => {
    setCurrentMonth({ year: now.getFullYear(), month: now.getMonth() + 1 });
  };

  const toggleCategory = (category: string) => {
    setSelectedCategories((prev) => {
      const next = new Set(prev);
      if (next.has(category)) {
        if (next.size > 1) next.delete(category);
      } else {
        next.add(category);
      }
      return next;
    });
  };

  // 현재 월 + 선택된 카테고리로 필터링
  const filteredEvents = useMemo(() => {
    const ym = `${currentMonth.year}-${String(currentMonth.month).padStart(2, '0')}`;
    return allEvents.filter((e) => {
      const matchMonth = e.date.startsWith(ym);
      const matchCategory = selectedCategories.has(e.category);
      return matchMonth && matchCategory;
    });
  }, [currentMonth, selectedCategories]);

  const isCurrentMonth = currentMonth.year === now.getFullYear() && currentMonth.month === now.getMonth() + 1;

  return (
    <div className="space-y-6">
      {/* 페이지 헤더 */}
      <div>
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">{t('haksa.calendarTitle')}</h1>
        <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">{t('haksa.calendarDesc')}</p>
      </div>

      {/* 월 선택 */}
      <div className="card p-4">
        <div className="flex items-center justify-center gap-4">
          <button
            onClick={handlePrev}
            className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-600 dark:text-slate-400 transition-colors"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <div className="flex items-center gap-2">
            <Calendar className="w-5 h-5 text-primary-600" />
            <span className="text-lg font-bold text-gray-900 dark:text-white">
              {currentMonth.year}년 {currentMonth.month}월
            </span>
          </div>
          <button
            onClick={handleNext}
            className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-600 dark:text-slate-400 transition-colors"
          >
            <ChevronRight className="w-5 h-5" />
          </button>
          {!isCurrentMonth && (
            <button
              onClick={handleToday}
              className="ml-2 px-3 py-1.5 text-xs font-medium text-primary-600 border border-primary-300 dark:border-primary-700 rounded-lg hover:bg-primary-50 dark:hover:bg-primary-900/20 transition-colors"
            >
              오늘
            </button>
          )}
        </div>
      </div>

      {/* 카테고리 범례 (클릭 필터) */}
      <div className="flex flex-wrap gap-3">
        {Object.entries(categoryStyles).map(([category, style]) => {
          const isActive = selectedCategories.has(category);
          return (
            <button
              key={category}
              onClick={() => toggleCategory(category)}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs transition-all border ${
                isActive
                  ? `${style.badge} border-current`
                  : 'bg-gray-50 text-gray-400 border-gray-200 dark:bg-gray-800 dark:text-gray-500 dark:border-gray-700 line-through'
              }`}
            >
              <span className={`w-2.5 h-2.5 rounded-full ${isActive ? style.dot : 'bg-gray-300 dark:bg-gray-600'}`} />
              {category}
            </button>
          );
        })}
        <span className="ml-auto text-xs text-gray-400 dark:text-gray-500 self-center">
          {filteredEvents.length}건
        </span>
      </div>

      {/* 일정 목록 */}
      <div className="space-y-3">
        {filteredEvents.length > 0 ? (
          filteredEvents.map((event) => {
            const style = categoryStyles[event.category];
            return (
              <div
                key={event.id}
                onClick={() => setSelectedEvent(event)}
                className="card p-4 flex items-start gap-4 hover:shadow-md hover:border-primary-200 dark:hover:border-primary-800 transition-all cursor-pointer"
              >
                {/* 날짜 */}
                <div className="flex-shrink-0 text-center min-w-[60px]">
                  <div className="text-xs text-gray-500 dark:text-slate-400">
                    {event.date.split('-')[1]}월
                  </div>
                  <div className="text-2xl font-bold text-gray-900 dark:text-white">
                    {event.date.split('-')[2]}
                  </div>
                </div>

                {/* 구분선 */}
                <div className={`w-1 self-stretch rounded-full ${style.dot}`} />

                {/* 내용 */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="text-sm font-semibold text-gray-900 dark:text-white">{event.title}</h3>
                    <span className={`inline-flex px-2 py-0.5 rounded-full text-[10px] font-medium ${style.badge}`}>
                      {event.category}
                    </span>
                  </div>
                  {event.description && (
                    <p className="text-xs text-gray-500 dark:text-slate-400">{event.description}</p>
                  )}
                  {(event.location || event.time) && (
                    <div className="flex items-center gap-3 mt-1.5">
                      {event.location && (
                        <span className="flex items-center gap-1 text-[10px] text-gray-400 dark:text-gray-500">
                          <MapPin className="w-3 h-3" />
                          {event.location}
                        </span>
                      )}
                      {event.time && (
                        <span className="flex items-center gap-1 text-[10px] text-gray-400 dark:text-gray-500">
                          <Clock className="w-3 h-3" />
                          {event.time}
                        </span>
                      )}
                    </div>
                  )}
                </div>

                {/* 날짜 텍스트 */}
                <div className="flex-shrink-0 text-[10px] text-gray-400 dark:text-slate-500">
                  {event.endDate ? `${event.date} ~ ${event.endDate}` : event.date}
                </div>
              </div>
            );
          })
        ) : (
          <div className="card p-12">
            <div className="flex flex-col items-center gap-2 text-gray-400 dark:text-gray-500">
              <Calendar className="w-10 h-10" />
              <p className="text-sm font-medium">
                {currentMonth.year}년 {currentMonth.month}월에 등록된 일정이 없습니다.
              </p>
            </div>
          </div>
        )}
      </div>

      {/* 일정 상세 모달 */}
      {selectedEvent && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm"
          onClick={() => setSelectedEvent(null)}
        >
          <div
            className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl w-full max-w-md mx-4 overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            {/* 모달 헤더 */}
            <div className={`px-6 py-4 ${categoryStyles[selectedEvent.category].badge}`}>
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold uppercase tracking-wider">{selectedEvent.category}</span>
                <button
                  onClick={() => setSelectedEvent(null)}
                  className="p-1 rounded-lg hover:bg-black/10 transition-colors"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
              <h2 className="text-lg font-bold mt-2">{selectedEvent.title}</h2>
            </div>

            {/* 모달 본문 */}
            <div className="px-6 py-5 space-y-4">
              {/* 날짜 */}
              <div className="flex items-center gap-3">
                <Calendar className="w-4 h-4 text-gray-400" />
                <span className="text-sm text-gray-700 dark:text-gray-300">
                  {selectedEvent.endDate
                    ? `${selectedEvent.date} ~ ${selectedEvent.endDate}`
                    : selectedEvent.date}
                </span>
              </div>

              {/* 시간 */}
              {selectedEvent.time && (
                <div className="flex items-center gap-3">
                  <Clock className="w-4 h-4 text-gray-400" />
                  <span className="text-sm text-gray-700 dark:text-gray-300">{selectedEvent.time}</span>
                </div>
              )}

              {/* 장소 */}
              {selectedEvent.location && (
                <div className="flex items-center gap-3">
                  <MapPin className="w-4 h-4 text-gray-400" />
                  <span className="text-sm text-gray-700 dark:text-gray-300">{selectedEvent.location}</span>
                </div>
              )}

              {/* 설명 */}
              {selectedEvent.description && (
                <div className="pt-3 border-t border-gray-100 dark:border-gray-700">
                  <p className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                    {selectedEvent.description}
                  </p>
                </div>
              )}
            </div>

            {/* 모달 하단 */}
            <div className="px-6 py-4 border-t border-gray-100 dark:border-gray-700 flex justify-end">
              <button
                onClick={() => setSelectedEvent(null)}
                className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
              >
                닫기
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
