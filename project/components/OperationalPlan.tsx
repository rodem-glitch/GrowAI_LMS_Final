import React from 'react';
import { ArrowLeft, Download, FileText } from 'lucide-react';

interface Course {
  id: string;
  classification: string;
  name: string;
  department: string;
  major: string;
  departmentName: string;
  trainingPeriod: string;
  trainingLevel: string;
  trainingTarget: string;
  trainingGoal: string;
  instructor: string;
  year: string;
  students: number;
  subjects: number;
}

interface OperationalPlanProps {
  course: Course;
  onBack: () => void;
}

export function OperationalPlan({ course, onBack }: OperationalPlanProps) {
  const handleDownloadPDF = () => {
    alert('PDF 다운로드 기능은 추후 구현될 예정입니다.');
  };

  return (
    <div className="max-w-5xl mx-auto">
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={onBack}
            className="flex items-center gap-2 px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            <span>목록으로</span>
          </button>
          <div>
            <h2 className="text-gray-900">운영계획서</h2>
            <p className="text-sm text-gray-600">{course.name}</p>
          </div>
        </div>
        <button
          onClick={handleDownloadPDF}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Download className="w-5 h-5" />
          <span>PDF 다운로드</span>
        </button>
      </div>

      {/* PDF Preview Container */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        {/* Document Header */}
        <div className="bg-gray-50 border-b border-gray-200 p-8 text-center">
          <div className="mb-4">
            <FileText className="w-16 h-16 mx-auto text-blue-600 mb-2" />
          </div>
          <h1 className="text-3xl mb-2 text-gray-900">교육과정 운영계획서</h1>
          <p className="text-xl text-gray-700">{course.name}</p>
        </div>

        {/* Document Content */}
        <div className="p-8 space-y-8">
          {/* 1. 기본 정보 */}
          <section>
            <h3 className="text-lg mb-4 pb-2 border-b-2 border-blue-600 text-gray-900">
              1. 기본 정보
            </h3>
            <div className="grid grid-cols-2 gap-4">
              <div className="flex border-b border-gray-200 py-3">
                <span className="w-32 text-gray-700">과정 분류</span>
                <span className="flex-1 text-gray-900">{course.classification}</span>
              </div>
              <div className="flex border-b border-gray-200 py-3">
                <span className="w-32 text-gray-700">과정명</span>
                <span className="flex-1 text-gray-900">{course.name}</span>
              </div>
              <div className="flex border-b border-gray-200 py-3">
                <span className="w-32 text-gray-700">계열</span>
                <span className="flex-1 text-gray-900">{course.department}</span>
              </div>
              <div className="flex border-b border-gray-200 py-3">
                <span className="w-32 text-gray-700">전공</span>
                <span className="flex-1 text-gray-900">{course.major}</span>
              </div>
              <div className="flex border-b border-gray-200 py-3">
                <span className="w-32 text-gray-700">학과명</span>
                <span className="flex-1 text-gray-900">{course.departmentName}</span>
              </div>
              <div className="flex border-b border-gray-200 py-3">
                <span className="w-32 text-gray-700">담당교수</span>
                <span className="flex-1 text-gray-900">{course.instructor}</span>
              </div>
            </div>
          </section>

          {/* 2. 교육훈련 정보 */}
          <section>
            <h3 className="text-lg mb-4 pb-2 border-b-2 border-blue-600 text-gray-900">
              2. 교육훈련 정보
            </h3>
            <div className="space-y-3">
              <div className="flex border-b border-gray-200 py-3">
                <span className="w-40 text-gray-700">교육훈련기간</span>
                <span className="flex-1 text-gray-900">{course.trainingPeriod}</span>
              </div>
              <div className="flex border-b border-gray-200 py-3">
                <span className="w-40 text-gray-700">교육훈련수준</span>
                <span className="flex-1 text-gray-900">{course.trainingLevel}</span>
              </div>
              <div className="flex border-b border-gray-200 py-3">
                <span className="w-40 text-gray-700">교육훈련대상자</span>
                <span className="flex-1 text-gray-900">{course.trainingTarget}</span>
              </div>
              <div className="flex border-b border-gray-200 py-3">
                <span className="w-40 text-gray-700">교육훈련목표</span>
                <span className="flex-1 text-gray-900 whitespace-pre-wrap">{course.trainingGoal}</span>
              </div>
            </div>
          </section>

          {/* 3. 교과편성 총괄표 */}
          <section>
            <h3 className="text-lg mb-4 pb-2 border-b-2 border-blue-600 text-gray-900">
              3. 교육훈련 교과편성 총괄표
            </h3>
            <div className="border border-gray-200 rounded-lg overflow-hidden">
              <table className="w-full">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-3 text-left text-sm text-gray-700 border-b border-gray-200">
                      구분
                    </th>
                    <th className="px-4 py-3 text-center text-sm text-gray-700 border-b border-gray-200">
                      시수
                    </th>
                    <th className="px-4 py-3 text-left text-sm text-gray-700 border-b border-gray-200">
                      내용
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr className="border-b border-gray-200">
                    <td className="px-4 py-3 text-sm text-gray-900">NCS</td>
                    <td className="px-4 py-3 text-sm text-gray-900 text-center">320</td>
                    <td className="px-4 py-3 text-sm text-gray-600">
                      데이터베이스 설계, SQL 프로그래밍, 데이터 모델링
                    </td>
                  </tr>
                  <tr className="border-b border-gray-200">
                    <td className="px-4 py-3 text-sm text-gray-900">비NCS</td>
                    <td className="px-4 py-3 text-sm text-gray-900 text-center">80</td>
                    <td className="px-4 py-3 text-sm text-gray-600">
                      프로젝트 실습, 사례 연구
                    </td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 text-sm text-gray-900">교양</td>
                    <td className="px-4 py-3 text-sm text-gray-900 text-center">40</td>
                    <td className="px-4 py-3 text-sm text-gray-600">
                      직업윤리, 의사소통능력
                    </td>
                  </tr>
                </tbody>
                <tfoot className="bg-gray-50">
                  <tr>
                    <td className="px-4 py-3 text-sm text-gray-900 border-t border-gray-200">
                      합계
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-900 text-center border-t border-gray-200">
                      440
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-600 border-t border-gray-200">
                      -
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </section>

          {/* 4. 교수계획서 */}
          <section>
            <h3 className="text-lg mb-4 pb-2 border-b-2 border-blue-600 text-gray-900">
              4. 교수계획서
            </h3>
            <div className="space-y-4">
              <div className="border border-gray-200 rounded-lg p-4">
                <div className="grid grid-cols-2 gap-4 mb-4">
                  <div className="flex">
                    <span className="w-32 text-gray-700">과목명</span>
                    <span className="flex-1 text-gray-900">데이터베이스 기초</span>
                  </div>
                  <div className="flex">
                    <span className="w-32 text-gray-700">대상학과</span>
                    <span className="flex-1 text-gray-900">{course.departmentName}</span>
                  </div>
                  <div className="flex">
                    <span className="w-32 text-gray-700">과정구분</span>
                    <span className="flex-1 text-gray-900">필수</span>
                  </div>
                  <div className="flex">
                    <span className="w-32 text-gray-700">교육훈련시수</span>
                    <span className="flex-1 text-gray-900">80시간</span>
                  </div>
                </div>
                <div className="space-y-2">
                  <div>
                    <span className="text-gray-700">교육목표: </span>
                    <span className="text-gray-900">
                      데이터베이스의 기본 개념과 SQL 활용 능력을 배양
                    </span>
                  </div>
                  <div>
                    <span className="text-gray-700">주교재: </span>
                    <span className="text-gray-900">데이터베이스 시스템 (저자명, 출판사)</span>
                  </div>
                </div>
              </div>
            </div>
          </section>

          {/* 5. 수행평가서 */}
          <section>
            <h3 className="text-lg mb-4 pb-2 border-b-2 border-blue-600 text-gray-900">
              5. 수행평가서
            </h3>
            <div className="border border-gray-200 rounded-lg overflow-hidden">
              <table className="w-full">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-3 text-left text-sm text-gray-700 border-b border-gray-200">
                      평가방법
                    </th>
                    <th className="px-4 py-3 text-left text-sm text-gray-700 border-b border-gray-200">
                      평가영역
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr className="border-b border-gray-200">
                    <td className="px-4 py-3 text-sm text-gray-900">필기시험</td>
                    <td className="px-4 py-3 text-sm text-gray-600">
                      이론 지식 평가 (40%)
                    </td>
                  </tr>
                  <tr className="border-b border-gray-200">
                    <td className="px-4 py-3 text-sm text-gray-900">실습평가</td>
                    <td className="px-4 py-3 text-sm text-gray-600">
                      SQL 작성 능력 평가 (30%)
                    </td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 text-sm text-gray-900">프로젝트</td>
                    <td className="px-4 py-3 text-sm text-gray-600">
                      데이터베이스 설계 및 구현 (30%)
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          {/* Footer */}
          <div className="pt-8 mt-8 border-t border-gray-200 text-center text-sm text-gray-600">
            <p>작성일: {new Date().toLocaleDateString('ko-KR')}</p>
            <p className="mt-2">담당교수: {course.instructor}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
