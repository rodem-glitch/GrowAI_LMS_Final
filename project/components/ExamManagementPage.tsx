import { useState, useEffect } from 'react';
import { Plus, Edit, Trash2, Search, ClipboardList, Calendar, Clock, FileQuestion, X, Save, Check } from 'lucide-react';
import { Question } from './QuestionBankPage';
import { QuestionCategory } from './QuestionCategoryPage';

// 시험 타입
export interface Exam {
  id: string;
  title: string;
  description: string;
  questionIds: string[];
  duration: number; // 분
  totalPoints: number;
  passingScore: number;
  shuffleQuestions: boolean;
  showResults: boolean;
  createdAt: string;
}

const EXAM_STORAGE_KEY = 'tutor_exams';
const QUESTION_STORAGE_KEY = 'tutor_question_bank';
const CATEGORY_STORAGE_KEY = 'tutor_question_categories';

const loadExams = (): Exam[] => {
  try {
    const saved = localStorage.getItem(EXAM_STORAGE_KEY);
    return saved ? JSON.parse(saved) : [];
  } catch {
    return [];
  }
};

const saveExams = (exams: Exam[]) => {
  localStorage.setItem(EXAM_STORAGE_KEY, JSON.stringify(exams));
};

const loadQuestions = (): Question[] => {
  try {
    const saved = localStorage.getItem(QUESTION_STORAGE_KEY);
    return saved ? JSON.parse(saved) : [];
  } catch {
    return [];
  }
};

const loadCategories = (): QuestionCategory[] => {
  try {
    const saved = localStorage.getItem(CATEGORY_STORAGE_KEY);
    return saved ? JSON.parse(saved) : [];
  } catch {
    return [];
  }
};

// 시험 목록을 외부에서도 사용할 수 있도록 export
export const getExamList = (): Exam[] => loadExams();

// 시험 상세 조회
export const getExamById = (examId: string): Exam | null => {
  const exams = loadExams();
  return exams.find(e => e.id === examId) || null;
};

// 시험에 포함된 문제 목록 조회
export const getExamQuestions = (examId: string): Question[] => {
  const exam = getExamById(examId);
  if (!exam) return [];
  const questions = loadQuestions();
  return exam.questionIds.map(id => questions.find(q => q.id === id)).filter(Boolean) as Question[];
};

export function ExamManagementPage() {
  const [exams, setExams] = useState<Exam[]>(() => loadExams());
  const [questions] = useState<Question[]>(() => loadQuestions());
  const [categories] = useState<QuestionCategory[]>(() => loadCategories());
  
  // 검색
  const [searchQuery, setSearchQuery] = useState('');
  
  // 모달 상태
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingExam, setEditingExam] = useState<Exam | null>(null);
  
  // 문제 선택 모달
  const [isQuestionModalOpen, setIsQuestionModalOpen] = useState(false);
  const [selectedQuestionIds, setSelectedQuestionIds] = useState<Set<string>>(new Set());
  const [questionFilterCategory, setQuestionFilterCategory] = useState<string>('');
  
  // 폼 상태
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    questionIds: [] as string[],
    duration: 60,
    passingScore: 60,
    shuffleQuestions: false,
    showResults: true,
  });

  useEffect(() => {
    saveExams(exams);
  }, [exams]);

  // 필터링된 시험 목록
  const filteredExams = exams.filter(e =>
    !searchQuery || e.title.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // 필터링된 문제 목록 (문제 선택 모달용)
  const filteredQuestions = questions.filter(q =>
    !questionFilterCategory || q.categoryId === questionFilterCategory
  );

  const openAddModal = () => {
    setEditingExam(null);
    setFormData({
      title: '',
      description: '',
      questionIds: [],
      duration: 60,
      passingScore: 60,
      shuffleQuestions: false,
      showResults: true,
    });
    setIsModalOpen(true);
  };

  const openEditModal = (exam: Exam) => {
    setEditingExam(exam);
    setFormData({
      title: exam.title,
      description: exam.description,
      questionIds: exam.questionIds,
      duration: exam.duration,
      passingScore: exam.passingScore,
      shuffleQuestions: exam.shuffleQuestions,
      showResults: exam.showResults,
    });
    setIsModalOpen(true);
  };

  const handleSave = () => {
    if (!formData.title.trim()) return;

    const totalPoints = formData.questionIds.reduce((sum, id) => {
      const q = questions.find(q => q.id === id);
      return sum + (q?.points || 0);
    }, 0);

    const examData = {
      title: formData.title.trim(),
      description: formData.description.trim(),
      questionIds: formData.questionIds,
      duration: formData.duration,
      totalPoints,
      passingScore: formData.passingScore,
      shuffleQuestions: formData.shuffleQuestions,
      showResults: formData.showResults,
    };

    if (editingExam) {
      setExams(prev =>
        prev.map(e =>
          e.id === editingExam.id ? { ...e, ...examData } : e
        )
      );
    } else {
      const newExam: Exam = {
        id: `exam_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        ...examData,
        createdAt: new Date().toISOString(),
      };
      setExams(prev => [...prev, newExam]);
    }

    setIsModalOpen(false);
  };

  const handleDelete = (id: string) => {
    if (!confirm('이 시험을 삭제하시겠습니까?')) return;
    setExams(prev => prev.filter(e => e.id !== id));
  };

  // 문제 선택 모달 열기
  const openQuestionModal = () => {
    setSelectedQuestionIds(new Set(formData.questionIds));
    setIsQuestionModalOpen(true);
  };

  // 문제 선택 토글
  const toggleQuestion = (id: string) => {
    setSelectedQuestionIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  // 문제 선택 확인
  const confirmQuestionSelection = () => {
    setFormData(prev => ({
      ...prev,
      questionIds: Array.from(selectedQuestionIds),
    }));
    setIsQuestionModalOpen(false);
  };

  // 선택된 문제 정보 가져오기
  const getSelectedQuestionsInfo = () => {
    const selected = formData.questionIds.map(id => questions.find(q => q.id === id)).filter(Boolean) as Question[];
    const totalPoints = selected.reduce((sum, q) => sum + q.points, 0);
    return { count: selected.length, totalPoints };
  };

  const questionInfo = getSelectedQuestionsInfo();

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">시험관리</h2>
          <p className="text-gray-500 mt-1">시험을 생성하고 관리합니다.</p>
        </div>
        <button
          onClick={openAddModal}
          className="flex items-center gap-2 px-4 py-2.5 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
        >
          <Plus className="w-5 h-5" />
          <span>시험 생성</span>
        </button>
      </div>

      {/* 검색 */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-4">
        <div className="relative max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="시험 검색..."
            className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>
      </div>

      {/* 시험 목록 */}
      <div className="grid gap-4">
        {filteredExams.length > 0 ? (
          filteredExams.map(exam => (
            <div
              key={exam.id}
              className="bg-white rounded-xl border border-gray-200 shadow-sm p-6 hover:shadow-md transition-shadow"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <h3 className="text-lg font-semibold text-gray-900">{exam.title}</h3>
                  {exam.description && (
                    <p className="text-gray-500 mt-1">{exam.description}</p>
                  )}
                  <div className="flex items-center gap-6 mt-4 text-sm text-gray-600">
                    <div className="flex items-center gap-2">
                      <FileQuestion className="w-4 h-4 text-indigo-500" />
                      <span>{exam.questionIds.length}문제</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <Clock className="w-4 h-4 text-blue-500" />
                      <span>{exam.duration}분</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-gray-500">총점:</span>
                      <span className="font-medium">{exam.totalPoints}점</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-gray-500">합격:</span>
                      <span className="font-medium">{exam.passingScore}점</span>
                    </div>
                  </div>
                </div>
                <div className="flex items-center gap-2 ml-4">
                  <button
                    onClick={() => openEditModal(exam)}
                    className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                    title="수정"
                  >
                    <Edit className="w-5 h-5" />
                  </button>
                  <button
                    onClick={() => handleDelete(exam.id)}
                    className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                    title="삭제"
                  >
                    <Trash2 className="w-5 h-5" />
                  </button>
                </div>
              </div>
            </div>
          ))
        ) : (
          <div className="bg-white rounded-xl border border-gray-200 shadow-sm text-center py-16 text-gray-400">
            <ClipboardList className="w-12 h-12 mx-auto mb-4 opacity-50" />
            <p>등록된 시험이 없습니다.</p>
            <button
              onClick={openAddModal}
              className="mt-4 text-indigo-600 hover:underline"
            >
              + 첫 번째 시험 생성하기
            </button>
          </div>
        )}
      </div>

      {/* 시험 생성/수정 모달 */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/50" onClick={() => setIsModalOpen(false)} />
          <div className="relative bg-white rounded-xl shadow-2xl w-full max-w-2xl mx-4 max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">
                {editingExam ? '시험 수정' : '시험 생성'}
              </h3>
              <button
                onClick={() => setIsModalOpen(false)}
                className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6 space-y-6">
              {/* 시험 제목 */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  시험 제목 <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={formData.title}
                  onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
                  placeholder="예: 중간고사"
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              {/* 시험 설명 */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">설명</label>
                <textarea
                  value={formData.description}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                  placeholder="시험에 대한 설명을 입력하세요"
                  rows={3}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none"
                />
              </div>

              {/* 문제 선택 */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">출제 문제</label>
                <button
                  type="button"
                  onClick={openQuestionModal}
                  className="w-full flex items-center justify-between px-4 py-3 border-2 border-dashed border-gray-300 rounded-lg text-gray-500 hover:border-indigo-400 hover:text-indigo-600 transition-colors"
                >
                  <span>
                    {formData.questionIds.length > 0
                      ? `${questionInfo.count}문제 선택됨 (총 ${questionInfo.totalPoints}점)`
                      : '문제은행에서 문제 선택'}
                  </span>
                  <FileQuestion className="w-5 h-5" />
                </button>
              </div>

              {/* 시험 시간 */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">시험 시간 (분)</label>
                  <input
                    type="number"
                    value={formData.duration}
                    onChange={(e) => setFormData(prev => ({ ...prev, duration: parseInt(e.target.value) || 0 }))}
                    min={1}
                    className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">합격 점수</label>
                  <input
                    type="number"
                    value={formData.passingScore}
                    onChange={(e) => setFormData(prev => ({ ...prev, passingScore: parseInt(e.target.value) || 0 }))}
                    min={0}
                    className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
              </div>

              {/* 옵션 */}
              <div className="space-y-3">
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formData.shuffleQuestions}
                    onChange={(e) => setFormData(prev => ({ ...prev, shuffleQuestions: e.target.checked }))}
                    className="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
                  />
                  <span className="text-sm text-gray-700">문제 순서 랜덤 배치</span>
                </label>
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formData.showResults}
                    onChange={(e) => setFormData(prev => ({ ...prev, showResults: e.target.checked }))}
                    className="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
                  />
                  <span className="text-sm text-gray-700">시험 종료 후 결과 공개</span>
                </label>
              </div>
            </div>

            <div className="sticky bottom-0 bg-white border-t border-gray-200 px-6 py-4 flex gap-3">
              <button
                onClick={() => setIsModalOpen(false)}
                className="flex-1 px-4 py-2.5 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              >
                취소
              </button>
              <button
                onClick={handleSave}
                disabled={!formData.title.trim()}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 transition-colors"
              >
                <Save className="w-4 h-4" />
                <span>저장</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 문제 선택 모달 */}
      {isQuestionModalOpen && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center">
          <div className="absolute inset-0 bg-black/50" onClick={() => setIsQuestionModalOpen(false)} />
          <div className="relative bg-white rounded-xl shadow-2xl w-full max-w-3xl mx-4 max-h-[85vh] overflow-hidden flex flex-col">
            <div className="flex-shrink-0 border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">
                문제 선택 ({selectedQuestionIds.size}개 선택됨)
              </h3>
              <button
                onClick={() => setIsQuestionModalOpen(false)}
                className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* 필터 */}
            <div className="flex-shrink-0 px-6 py-3 border-b border-gray-100 bg-gray-50">
              <select
                value={questionFilterCategory}
                onChange={(e) => setQuestionFilterCategory(e.target.value)}
                className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="">전체 카테고리</option>
                {categories.map(c => (
                  <option key={c.id} value={c.id}>{c.name}</option>
                ))}
              </select>
            </div>

            {/* 문제 목록 */}
            <div className="flex-1 overflow-y-auto">
              {filteredQuestions.length > 0 ? (
                <div className="divide-y divide-gray-100">
                  {filteredQuestions.map(question => (
                    <div
                      key={question.id}
                      className={`px-6 py-4 cursor-pointer transition-colors ${
                        selectedQuestionIds.has(question.id)
                          ? 'bg-indigo-50'
                          : 'hover:bg-gray-50'
                      }`}
                      onClick={() => toggleQuestion(question.id)}
                    >
                      <div className="flex items-start gap-4">
                        <div className={`flex-shrink-0 w-6 h-6 rounded border-2 flex items-center justify-center mt-0.5 ${
                          selectedQuestionIds.has(question.id)
                            ? 'border-indigo-500 bg-indigo-500 text-white'
                            : 'border-gray-300'
                        }`}>
                          {selectedQuestionIds.has(question.id) && <Check className="w-4 h-4" />}
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="font-medium text-gray-900">{question.title}</div>
                          {question.content && (
                            <div className="text-sm text-gray-500 mt-1 truncate">{question.content}</div>
                          )}
                          <div className="flex items-center gap-3 mt-2 text-xs text-gray-500">
                            <span className={`px-2 py-0.5 rounded-full ${
                              question.type === 'multiple_choice' ? 'bg-blue-100 text-blue-700' :
                              question.type === 'short_answer' ? 'bg-green-100 text-green-700' :
                              'bg-purple-100 text-purple-700'
                            }`}>
                              {question.type === 'multiple_choice' ? '객관식' : question.type === 'short_answer' ? '주관식' : 'OX형'}
                            </span>
                            <span>{question.points}점</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center py-12 text-gray-400">
                  <FileQuestion className="w-10 h-10 mx-auto mb-3 opacity-50" />
                  <p>문제가 없습니다.</p>
                  <p className="text-sm mt-1">문제은행에서 먼저 문제를 추가해주세요.</p>
                </div>
              )}
            </div>

            <div className="flex-shrink-0 border-t border-gray-200 px-6 py-4 flex gap-3">
              <button
                onClick={() => setIsQuestionModalOpen(false)}
                className="flex-1 px-4 py-2.5 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              >
                취소
              </button>
              <button
                onClick={confirmQuestionSelection}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
              >
                <Check className="w-4 h-4" />
                <span>선택 완료</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
