import { useState } from 'react';
import { Briefcase, ChevronDown, ChevronRight } from 'lucide-react';
import { AssignmentCreateModal } from './AssignmentCreateModal';

export function AssignmentManagementTabWrapper() {
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [expandedAssignment, setExpandedAssignment] = useState<number | null>(null);

  const assignments = [
    {
      id: 1,
      title: 'HTML 포트폴리오 페이지 제작',
      dueDate: '2024.03.25',
      submitted: 22,
      total: 28,
    },
    { id: 2, title: 'CSS 레이아웃 실습', dueDate: '2024.04.10', submitted: 20, total: 28 },
    {
      id: 3,
      title: 'JavaScript 계산기 만들기',
      dueDate: '2024.05.05',
      submitted: 15,
      total: 28,
    },
  ];

  const handleCreateAssignment = (assignmentData: any) => {
    console.log('새 과제 등록:', assignmentData);
    // 실제로는 여기서 과제 데이터를 저장하는 로직이 들어갑니다
    alert('과제가 등록되었습니다.');
  };

  return (
    <>
      <div className="space-y-4">
        <div className="flex justify-end">
          <button 
            onClick={() => setShowCreateModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Briefcase className="w-4 h-4" />
            <span>과제 등록</span>
          </button>
        </div>
        {assignments.map((assignment) => (
          <div
            key={assignment.id}
            className="border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <button
              onClick={() =>
                setExpandedAssignment(expandedAssignment === assignment.id ? null : assignment.id)
              }
              className="w-full p-4 text-left"
            >
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <div className="text-gray-900 mb-1">{assignment.title}</div>
                  <div className="text-sm text-gray-600">마감일: {assignment.dueDate}</div>
                </div>
                <div className="flex items-center gap-4">
                  <div className="text-right">
                    <div className="text-sm text-gray-600">제출 현황</div>
                    <div className="text-gray-900">
                      {assignment.submitted} / {assignment.total}명
                    </div>
                  </div>
                  {expandedAssignment === assignment.id ? (
                    <ChevronDown className="w-5 h-5 text-gray-400" />
                  ) : (
                    <ChevronRight className="w-5 h-5 text-gray-400" />
                  )}
                </div>
              </div>
            </button>
            {expandedAssignment === assignment.id && (
              <div className="px-4 pb-4 space-y-2 border-t border-gray-200 pt-4">
                <div className="flex gap-2">
                  <button className="px-3 py-2 text-sm bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors">
                    과제 수정
                  </button>
                  <button className="px-3 py-2 text-sm bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors">
                    제출 현황 보기
                  </button>
                  <button className="px-3 py-2 text-sm bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors">
                    과제 삭제
                  </button>
                </div>
              </div>
            )}
          </div>
        ))}
      </div>

      <AssignmentCreateModal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onSave={handleCreateAssignment}
      />
    </>
  );
}
