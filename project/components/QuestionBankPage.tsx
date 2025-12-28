import { useState, useEffect } from 'react';
import { Plus, Edit, Trash2, Search, Filter, FileQuestion, CheckCircle, Circle, X, Save, ChevronDown } from 'lucide-react';
import { QuestionCategory } from './QuestionCategoryPage';

// 문제 타입
export type QuestionType = 'multiple_choice' | 'short_answer' | 'ox';

export interface QuestionChoice {
  id: string;
  text: string;
  isCorrect: boolean;
}

export interface Question {
  id: string;
  categoryId: string | null;
  type: QuestionType;
  title: string;
  content: string;
  choices?: QuestionChoice[]; // 객관식
  correctAnswer?: string; // 주관식/OX
  points: number;
  createdAt: string;
}

const STORAGE_KEY = 'tutor_question_bank';
const CATEGORY_STORAGE_KEY = 'tutor_question_categories';

const loadQuestions = (): Question[] => {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    return saved ? JSON.parse(saved) : [];
  } catch {
    return [];
  }
};

const saveQuestions = (questions: Question[]) => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(questions));
};

const loadCategories = (): QuestionCategory[] => {
  try {
    const saved = localStorage.getItem(CATEGORY_STORAGE_KEY);
    return saved ? JSON.parse(saved) : [];
  } catch {
    return [];
  }
};

const questionTypeLabels: Record<QuestionType, string> = {
  multiple_choice: '객관식',
  short_answer: '주관식',
  ox: 'OX형',
};

const questionTypeColors: Record<QuestionType, string> = {
  multiple_choice: 'bg-blue-100 text-blue-700',
  short_answer: 'bg-green-100 text-green-700',
  ox: 'bg-purple-100 text-purple-700',
};

export function QuestionBankPage() {
  const [questions, setQuestions] = useState<Question[]>(() => loadQuestions());
  const [categories] = useState<QuestionCategory[]>(() => loadCategories());
  
  // 필터
  const [searchQuery, setSearchQuery] = useState('');
  const [filterCategory, setFilterCategory] = useState<string>('');
  const [filterType, setFilterType] = useState<QuestionType | ''>('');
  
  // 모달 상태
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingQuestion, setEditingQuestion] = useState<Question | null>(null);
  
  // 폼 상태
  const [formData, setFormData] = useState({
    categoryId: '' as string | null,
    type: 'multiple_choice' as QuestionType,
    title: '',
    content: '',
    points: 5,
    choices: [
      { id: '1', text: '', isCorrect: false },
      { id: '2', text: '', isCorrect: false },
      { id: '3', text: '', isCorrect: false },
      { id: '4', text: '', isCorrect: false },
    ] as QuestionChoice[],
    correctAnswer: '',
  });

  useEffect(() => {
    saveQuestions(questions);
  }, [questions]);

  // 필터링된 문제 목록
  const filteredQuestions = questions.filter(q => {
    if (searchQuery && !q.title.toLowerCase().includes(searchQuery.toLowerCase()) && 
        !q.content.toLowerCase().includes(searchQuery.toLowerCase())) {
      return false;
    }
    if (filterCategory && q.categoryId !== filterCategory) return false;
    if (filterType && q.type !== filterType) return false;
    return true;
  });

  const openAddModal = () => {
    setEditingQuestion(null);
    setFormData({
      categoryId: null,
      type: 'multiple_choice',
      title: '',
      content: '',
      points: 5,
      choices: [
        { id: '1', text: '', isCorrect: false },
        { id: '2', text: '', isCorrect: false },
        { id: '3', text: '', isCorrect: false },
        { id: '4', text: '', isCorrect: false },
      ],
      correctAnswer: '',
    });
    setIsModalOpen(true);
  };

  const openEditModal = (question: Question) => {
    setEditingQuestion(question);
    setFormData({
      categoryId: question.categoryId,
      type: question.type,
      title: question.title,
      content: question.content,
      points: question.points,
      choices: question.choices || [
        { id: '1', text: '', isCorrect: false },
        { id: '2', text: '', isCorrect: false },
        { id: '3', text: '', isCorrect: false },
        { id: '4', text: '', isCorrect: false },
      ],
      correctAnswer: question.correctAnswer || '',
    });
    setIsModalOpen(true);
  };

  const handleSave = () => {
    if (!formData.title.trim()) return;

    const questionData = {
      categoryId: formData.categoryId || null,
      type: formData.type,
      title: formData.title.trim(),
      content: formData.content.trim(),
      points: formData.points,
      choices: formData.type === 'multiple_choice' ? formData.choices : undefined,
      correctAnswer: formData.type !== 'multiple_choice' ? formData.correctAnswer : undefined,
    };

    if (editingQuestion) {
      setQuestions(prev =>
        prev.map(q =>
          q.id === editingQuestion.id
            ? { ...q, ...questionData }
            : q
        )
      );
    } else {
      const newQuestion: Question = {
        id: `q_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        ...questionData,
        createdAt: new Date().toISOString(),
      };
      setQuestions(prev => [...prev, newQuestion]);
    }

    setIsModalOpen(false);
  };

  const handleDelete = (id: string) => {
    if (!confirm('이 문제를 삭제하시겠습니까?')) return;
    setQuestions(prev => prev.filter(q => q.id !== id));
  };

  const getCategoryName = (categoryId: string | null) => {
    if (!categoryId) return '-';
    const category = categories.find(c => c.id === categoryId);
    return category?.name || '-';
  };

  const updateChoice = (index: number, field: 'text' | 'isCorrect', value: string | boolean) => {
    setFormData(prev => ({
      ...prev,
      choices: prev.choices.map((c, i) => {
        if (i === index) {
          return { ...c, [field]: value };
        }
        // 정답 선택 시 다른 선택지는 오답으로
        if (field === 'isCorrect' && value === true) {
          return { ...c, isCorrect: false };
        }
        return c;
      }),
    }));
  };

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">문제은행</h2>
          <p className="text-gray-500 mt-1">시험에 사용할 문제를 관리합니다.</p>
        </div>
        <button
          onClick={openAddModal}
          className="flex items-center gap-2 px-4 py-2.5 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
        >
          <Plus className="w-5 h-5" />
          <span>문제 추가</span>
        </button>
      </div>

      {/* 필터 */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-4">
        <div className="flex items-center gap-4 flex-wrap">
          <div className="flex-1 min-w-[200px]">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="문제 검색..."
                className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
          </div>
          <select
            value={filterCategory}
            onChange={(e) => setFilterCategory(e.target.value)}
            className="px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="">전체 카테고리</option>
            {categories.map(c => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </select>
          <select
            value={filterType}
            onChange={(e) => setFilterType(e.target.value as QuestionType | '')}
            className="px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="">전체 유형</option>
            <option value="multiple_choice">객관식</option>
            <option value="short_answer">주관식</option>
            <option value="ox">OX형</option>
          </select>
        </div>
      </div>

      {/* 문제 목록 */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
        {filteredQuestions.length > 0 ? (
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">문제</th>
                <th className="px-6 py-4 text-center text-xs font-medium text-gray-500 uppercase tracking-wider w-28">유형</th>
                <th className="px-6 py-4 text-center text-xs font-medium text-gray-500 uppercase tracking-wider w-32">카테고리</th>
                <th className="px-6 py-4 text-center text-xs font-medium text-gray-500 uppercase tracking-wider w-20">배점</th>
                <th className="px-6 py-4 text-center text-xs font-medium text-gray-500 uppercase tracking-wider w-24">관리</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {filteredQuestions.map(question => (
                <tr key={question.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="font-medium text-gray-900">{question.title}</div>
                    {question.content && (
                      <div className="text-sm text-gray-500 truncate max-w-md">{question.content}</div>
                    )}
                  </td>
                  <td className="px-6 py-4 text-center">
                    <span className={`px-2.5 py-1 text-xs font-medium rounded-full ${questionTypeColors[question.type]}`}>
                      {questionTypeLabels[question.type]}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-center text-sm text-gray-600">
                    {getCategoryName(question.categoryId)}
                  </td>
                  <td className="px-6 py-4 text-center text-sm font-medium text-gray-900">
                    {question.points}점
                  </td>
                  <td className="px-6 py-4 text-center">
                    <div className="flex items-center justify-center gap-1">
                      <button
                        onClick={() => openEditModal(question)}
                        className="p-1.5 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded transition-colors"
                        title="수정"
                      >
                        <Edit className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleDelete(question.id)}
                        className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded transition-colors"
                        title="삭제"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <div className="text-center py-16 text-gray-400">
            <FileQuestion className="w-12 h-12 mx-auto mb-4 opacity-50" />
            <p>등록된 문제가 없습니다.</p>
            <button
              onClick={openAddModal}
              className="mt-4 text-indigo-600 hover:underline"
            >
              + 첫 번째 문제 추가하기
            </button>
          </div>
        )}
      </div>

      {/* 통계 */}
      <div className="text-sm text-gray-500">
        총 {questions.length}개 문제 | 표시: {filteredQuestions.length}개
      </div>

      {/* 문제 추가/수정 모달 */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/50" onClick={() => setIsModalOpen(false)} />
          <div className="relative bg-white rounded-xl shadow-2xl w-full max-w-2xl mx-4 max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">
                {editingQuestion ? '문제 수정' : '문제 추가'}
              </h3>
              <button
                onClick={() => setIsModalOpen(false)}
                className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6 space-y-6">
              {/* 문제 유형 선택 */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">문제 유형</label>
                <div className="flex gap-3">
                  {(['multiple_choice', 'short_answer', 'ox'] as QuestionType[]).map(type => (
                    <button
                      key={type}
                      type="button"
                      onClick={() => setFormData(prev => ({ ...prev, type }))}
                      className={`flex-1 py-3 px-4 rounded-lg border-2 transition-colors ${
                        formData.type === type
                          ? 'border-indigo-500 bg-indigo-50 text-indigo-700'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}
                    >
                      {questionTypeLabels[type]}
                    </button>
                  ))}
                </div>
              </div>

              {/* 카테고리 */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">카테고리</label>
                <select
                  value={formData.categoryId || ''}
                  onChange={(e) => setFormData(prev => ({ ...prev, categoryId: e.target.value || null }))}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <option value="">카테고리 없음</option>
                  {categories.map(c => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>

              {/* 문제 제목 */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  문제 제목 <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={formData.title}
                  onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
                  placeholder="문제 제목을 입력하세요"
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              {/* 문제 내용 */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">문제 내용</label>
                <textarea
                  value={formData.content}
                  onChange={(e) => setFormData(prev => ({ ...prev, content: e.target.value }))}
                  placeholder="문제 내용을 입력하세요"
                  rows={4}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none"
                />
              </div>

              {/* 객관식 선택지 */}
              {formData.type === 'multiple_choice' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">선택지</label>
                  <div className="space-y-3">
                    {formData.choices.map((choice, index) => (
                      <div key={choice.id} className="flex items-center gap-3">
                        <button
                          type="button"
                          onClick={() => updateChoice(index, 'isCorrect', true)}
                          className={`flex-shrink-0 w-6 h-6 rounded-full border-2 flex items-center justify-center transition-colors ${
                            choice.isCorrect
                              ? 'border-green-500 bg-green-500 text-white'
                              : 'border-gray-300 hover:border-green-400'
                          }`}
                        >
                          {choice.isCorrect && <CheckCircle className="w-4 h-4" />}
                        </button>
                        <span className="text-sm text-gray-500 w-6">{index + 1}.</span>
                        <input
                          type="text"
                          value={choice.text}
                          onChange={(e) => updateChoice(index, 'text', e.target.value)}
                          placeholder={`선택지 ${index + 1}`}
                          className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                        />
                      </div>
                    ))}
                  </div>
                  <p className="text-xs text-gray-400 mt-2">원형 버튼을 클릭하여 정답을 선택하세요.</p>
                </div>
              )}

              {/* 주관식 정답 */}
              {formData.type === 'short_answer' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">정답</label>
                  <input
                    type="text"
                    value={formData.correctAnswer}
                    onChange={(e) => setFormData(prev => ({ ...prev, correctAnswer: e.target.value }))}
                    placeholder="정답을 입력하세요"
                    className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
              )}

              {/* OX 정답 */}
              {formData.type === 'ox' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">정답</label>
                  <div className="flex gap-4">
                    <button
                      type="button"
                      onClick={() => setFormData(prev => ({ ...prev, correctAnswer: 'O' }))}
                      className={`flex-1 py-4 text-2xl font-bold rounded-lg border-2 transition-colors ${
                        formData.correctAnswer === 'O'
                          ? 'border-green-500 bg-green-50 text-green-600'
                          : 'border-gray-200 hover:border-gray-300 text-gray-400'
                      }`}
                    >
                      O
                    </button>
                    <button
                      type="button"
                      onClick={() => setFormData(prev => ({ ...prev, correctAnswer: 'X' }))}
                      className={`flex-1 py-4 text-2xl font-bold rounded-lg border-2 transition-colors ${
                        formData.correctAnswer === 'X'
                          ? 'border-red-500 bg-red-50 text-red-600'
                          : 'border-gray-200 hover:border-gray-300 text-gray-400'
                      }`}
                    >
                      X
                    </button>
                  </div>
                </div>
              )}

              {/* 배점 */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">배점</label>
                <input
                  type="number"
                  value={formData.points}
                  onChange={(e) => setFormData(prev => ({ ...prev, points: parseInt(e.target.value) || 0 }))}
                  min={1}
                  className="w-32 px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
                <span className="ml-2 text-gray-500">점</span>
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
    </div>
  );
}
