import React, { useState } from 'react';
import { Plus, Trash2, Save } from 'lucide-react';

interface CurriculumItem {
  id: string;
  type: 'NCS' | 'non-NCS' | 'liberal-arts';
  hours: string;
  description: string;
}

interface TeachingPlan {
  id: string;
  courseName: string;
  targetDepartment: string;
  courseType: string;
  trainingHours: string;
  instructor: string;
  goals: string;
  textbook: string;
  mainPlan: string;
}

interface Evaluation {
  id: string;
  method: string;
  area: string;
}

export function CreateCourseForm() {
  const [curriculumItems, setCurriculumItems] = useState<CurriculumItem[]>([]);
  const [teachingPlans, setTeachingPlans] = useState<TeachingPlan[]>([]);
  const [evaluations, setEvaluations] = useState<Evaluation[]>([]);

  const addCurriculumItem = () => {
    setCurriculumItems([
      ...curriculumItems,
      { id: Date.now().toString(), type: 'NCS', hours: '', description: '' },
    ]);
  };

  const removeCurriculumItem = (id: string) => {
    setCurriculumItems(curriculumItems.filter((item) => item.id !== id));
  };

  const updateCurriculumItem = (id: string, field: keyof CurriculumItem, value: string) => {
    setCurriculumItems(
      curriculumItems.map((item) =>
        item.id === id ? { ...item, [field]: value } : item
      )
    );
  };

  const addTeachingPlan = () => {
    setTeachingPlans([
      ...teachingPlans,
      {
        id: Date.now().toString(),
        courseName: '',
        targetDepartment: '',
        courseType: '',
        trainingHours: '',
        instructor: '',
        goals: '',
        textbook: '',
        mainPlan: '',
      },
    ]);
  };

  const removeTeachingPlan = (id: string) => {
    setTeachingPlans(teachingPlans.filter((plan) => plan.id !== id));
  };

  const updateTeachingPlan = (id: string, field: keyof TeachingPlan, value: string) => {
    setTeachingPlans(
      teachingPlans.map((plan) =>
        plan.id === id ? { ...plan, [field]: value } : plan
      )
    );
  };

  const addEvaluation = () => {
    setEvaluations([
      ...evaluations,
      { id: Date.now().toString(), method: '', area: '' },
    ]);
  };

  const removeEvaluation = (id: string) => {
    setEvaluations(evaluations.filter((evalItem) => evalItem.id !== id));
  };

  const updateEvaluation = (id: string, field: keyof Evaluation, value: string) => {
    setEvaluations(
      evaluations.map((evalItem) =>
        evalItem.id === id ? { ...evalItem, [field]: value } : evalItem
      )
    );
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    alert('과정이 개설되었습니다.');
  };

  return (
    <form onSubmit={handleSubmit} className="max-w-6xl mx-auto">
      <div className="mb-8">
        <h2 className="text-gray-900 mb-2">과정 개설</h2>
        <p className="text-gray-600">새로운 교육 과정을 개설합니다.</p>
      </div>

      {/* 기본 정보 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <h3 className="text-gray-900 mb-4">기본 정보</h3>
        <div className="grid grid-cols-2 gap-4">
          <div className="col-span-2">
            <label className="block text-sm text-gray-700 mb-2">
              과정 분류 <span className="text-red-500">*</span>
            </label>
            <select className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option value="">선택하세요</option>
              <option value="degree-major">학위전공</option>
              <option value="degree-major-advanced">학위전공심화</option>
              <option value="professional-tech">전문기술</option>
              <option value="high-tech">하이테크</option>
              <option value="master-craftsman">기능장</option>
              <option value="high-school-consignment">고교위탁</option>
              <option value="new-seniors">신중년</option>
            </select>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">과정명</label>
            <input
              type="text"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="과정명을 입력하세요"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">계열</label>
            <input
              type="text"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="계열을 입력하세요"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">전공</label>
            <input
              type="text"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="전공을 입력하세요"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">학과명</label>
            <input
              type="text"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="학과명을 입력하세요"
            />
          </div>
        </div>
      </div>

      {/* 교육훈련 정보 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <h3 className="text-gray-900 mb-4">교육훈련 정보</h3>
        <div className="grid grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block text-sm text-gray-700 mb-2">교육훈련기간</label>
            <input
              type="text"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="예: 2024.03.01 - 2024.12.31"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">교육훈련수준</label>
            <select className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option value="">선택하세요</option>
              <option value="beginner">초급</option>
              <option value="intermediate">중급</option>
              <option value="advanced">고급</option>
            </select>
          </div>
        </div>
        <div className="mb-4">
          <label className="block text-sm text-gray-700 mb-2">교육훈련대상자</label>
          <input
            type="text"
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="교육훈련대상자를 입력하세요"
          />
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-2">교육훈련목표</label>
          <textarea
            rows={4}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="교육훈련목표를 입력하세요"
          />
        </div>
      </div>

      {/* 교육훈련 교과편성 총괄표 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-gray-900">교육훈련 교과편성 총괄표</h3>
          <button
            type="button"
            onClick={addCurriculumItem}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            <span>항목 추가</span>
          </button>
        </div>
        {curriculumItems.length > 0 ? (
          <div className="space-y-3">
            {curriculumItems.map((item) => (
              <div key={item.id} className="flex gap-3 items-start p-4 bg-gray-50 rounded-lg">
                <div className="flex-1 grid grid-cols-3 gap-3">
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">구분</label>
                    <select
                      value={item.type}
                      onChange={(e) =>
                        updateCurriculumItem(item.id, 'type', e.target.value)
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="NCS">NCS</option>
                      <option value="non-NCS">비NCS</option>
                      <option value="liberal-arts">교양</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">시수</label>
                    <input
                      type="text"
                      value={item.hours}
                      onChange={(e) =>
                        updateCurriculumItem(item.id, 'hours', e.target.value)
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="시수"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">설명</label>
                    <input
                      type="text"
                      value={item.description}
                      onChange={(e) =>
                        updateCurriculumItem(item.id, 'description', e.target.value)
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="설명"
                    />
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => removeCurriculumItem(item.id)}
                  className="mt-6 p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                >
                  <Trash2 className="w-5 h-5" />
                </button>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500">
            <p>교과편성 항목을 추가해주세요</p>
          </div>
        )}
      </div>

      {/* 교수계획서 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-gray-900">교수계획서</h3>
          <button
            type="button"
            onClick={addTeachingPlan}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            <span>계획서 추가</span>
          </button>
        </div>
        {teachingPlans.length > 0 ? (
          <div className="space-y-4">
            {teachingPlans.map((plan) => (
              <div key={plan.id} className="p-4 bg-gray-50 rounded-lg">
                <div className="grid grid-cols-2 gap-3 mb-3">
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">교과목명</label>
                    <input
                      type="text"
                      value={plan.courseName}
                      onChange={(e) =>
                        updateTeachingPlan(plan.id, 'courseName', e.target.value)
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="교과목명"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">대상학과</label>
                    <input
                      type="text"
                      value={plan.targetDepartment}
                      onChange={(e) =>
                        updateTeachingPlan(plan.id, 'targetDepartment', e.target.value)
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="대상학과"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">교과구분</label>
                    <input
                      type="text"
                      value={plan.courseType}
                      onChange={(e) =>
                        updateTeachingPlan(plan.id, 'courseType', e.target.value)
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="교과구분"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">교육훈련시간</label>
                    <input
                      type="text"
                      value={plan.trainingHours}
                      onChange={(e) =>
                        updateTeachingPlan(plan.id, 'trainingHours', e.target.value)
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="교육훈련시간"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">교수명</label>
                    <input
                      type="text"
                      value={plan.instructor}
                      onChange={(e) =>
                        updateTeachingPlan(plan.id, 'instructor', e.target.value)
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="교수명"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">교재</label>
                    <input
                      type="text"
                      value={plan.textbook}
                      onChange={(e) =>
                        updateTeachingPlan(plan.id, 'textbook', e.target.value)
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="교재"
                    />
                  </div>
                </div>
                <div className="mb-3">
                  <label className="block text-sm text-gray-700 mb-1">지도목표</label>
                  <textarea
                    rows={2}
                    value={plan.goals}
                    onChange={(e) =>
                      updateTeachingPlan(plan.id, 'goals', e.target.value)
                    }
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="지도목표"
                  />
                </div>
                <div className="mb-3">
                  <label className="block text-sm text-gray-700 mb-1">주요 교수계획</label>
                  <textarea
                    rows={3}
                    value={plan.mainPlan}
                    onChange={(e) =>
                      updateTeachingPlan(plan.id, 'mainPlan', e.target.value)
                    }
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="주요 교수계획"
                  />
                </div>
                <div className="flex justify-end">
                  <button
                    type="button"
                    onClick={() => removeTeachingPlan(plan.id)}
                    className="flex items-center gap-2 px-3 py-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                    <span>삭제</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500">
            <p>교수계획서를 추가해주세요</p>
          </div>
        )}
      </div>

      {/* 수행평가서 */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-gray-900">수행평가서</h3>
          <button
            type="button"
            onClick={addEvaluation}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            <span>평가 추가</span>
          </button>
        </div>
        {evaluations.length > 0 ? (
          <div className="space-y-3">
            {evaluations.map((evaluation) => (
              <div key={evaluation.id} className="flex gap-3 items-start p-4 bg-gray-50 rounded-lg">
                <div className="flex-1 grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">평가방법</label>
                    <input
                      type="text"
                      value={evaluation.method}
                      onChange={(e) =>
                        updateEvaluation(evaluation.id, 'method', e.target.value)
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="예: 필기시험, 실기평가, 과제"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-700 mb-1">평가영역</label>
                    <input
                      type="text"
                      value={evaluation.area}
                      onChange={(e) =>
                        updateEvaluation(evaluation.id, 'area', e.target.value)
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="예: 이론, 실습, 태도"
                    />
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => removeEvaluation(evaluation.id)}
                  className="mt-6 p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                >
                  <Trash2 className="w-5 h-5" />
                </button>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500">
            <p>수행평가 항목을 추가해주세요</p>
          </div>
        )}
      </div>

      {/* 제출 버튼 */}
      <div className="flex justify-end gap-3">
        <button
          type="button"
          className="px-6 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
        >
          취소
        </button>
        <button
          type="submit"
          className="flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Save className="w-5 h-5" />
          <span>과정 개설</span>
        </button>
      </div>
    </form>
  );
}