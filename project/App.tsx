import { useState } from 'react';
import { GraduationCap, BookOpen, FolderPlus, Compass, Library, ChevronDown, ChevronRight, Heart, RefreshCw, ClipboardList } from 'lucide-react';
import { CreateCourseForm } from './components/CreateCourseForm';
import { MyCoursesList } from './components/MyCoursesList';
import { CourseExplorer } from './components/CourseExplorer';
import { Dashboard } from './components/Dashboard';
import { ContentLibraryPage } from './components/ContentLibraryPage';
import { QuestionCategoryPage } from './components/QuestionCategoryPage';
import { QuestionBankPage } from './components/QuestionBankPage';
import { ExamManagementPage } from './components/ExamManagementPage';

export default function App() {
  const [activeMenu, setActiveMenu] = useState<string>('dashboard');
  const [contentLibraryExpanded, setContentLibraryExpanded] = useState(false);
  const [examMenuExpanded, setExamMenuExpanded] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0); // 컴포넌트 재렌더링용 키

  // 콘텐츠 라이브러리 하위 메뉴 여부 확인
  const isContentLibrarySubMenu = activeMenu === 'content-all' || activeMenu === 'content-favorites';
  
  // 시험관리 하위 메뉴 여부 확인
  const isExamSubMenu = activeMenu === 'exam-categories' || activeMenu === 'exam-questions' || activeMenu === 'exam-management';

  const handleContentLibraryClick = () => {
    if (!contentLibraryExpanded) {
      setContentLibraryExpanded(true);
      setActiveMenu('content-all');
    } else {
      setContentLibraryExpanded(!contentLibraryExpanded);
    }
  };

  const handleExamMenuClick = () => {
    if (!examMenuExpanded) {
      setExamMenuExpanded(true);
      setActiveMenu('exam-categories');
    } else {
      setExamMenuExpanded(!examMenuExpanded);
    }
  };

  // 현재 화면 새로고침
  const handleRefresh = () => {
    setRefreshKey(prev => prev + 1);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-50">
        <div className="px-8 py-4">
          <div className="flex items-center justify-between">
            {/* Logo */}
            <div className="flex items-center gap-3">
              <div className="bg-blue-600 p-2 rounded-lg">
                <GraduationCap className="w-8 h-8 text-white" />
              </div>
              <div>
                <h1 className="text-gray-900">교수자 LMS</h1>
                <p className="text-sm text-gray-500">Learning Management System</p>
              </div>
            </div>
            
            {/* 새로고침 버튼 */}
            <button
              onClick={handleRefresh}
              className="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
              title="현재 화면 새로고침"
            >
              <RefreshCw className="w-5 h-5" />
            </button>
          </div>
        </div>
      </header>

      <div className="flex">
        {/* Left Navigation Sidebar - Fixed Position */}
        <aside className="w-64 bg-white border-r border-gray-200 fixed top-[73px] left-0 h-[calc(100vh-73px)] overflow-y-auto z-40">
          <nav className="p-4 flex flex-col gap-2">
            <button
              onClick={() => setActiveMenu('dashboard')}
              className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors text-left ${
                activeMenu === 'dashboard'
                  ? 'bg-blue-600 text-white'
                  : 'text-gray-700 hover:bg-gray-100'
              }`}
            >
              <GraduationCap className="w-5 h-5" />
              <span>대시보드</span>
            </button>
            
            {/* 과정탐색 */}
            <button
              onClick={() => setActiveMenu('explore')}
              className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors text-left ${
                activeMenu === 'explore'
                  ? 'bg-blue-600 text-white'
                  : 'text-gray-700 hover:bg-gray-100'
              }`}
            >
              <Compass className="w-5 h-5" />
              <span>과정탐색</span>
            </button>
            
            <button
              onClick={() => setActiveMenu('courses')}
              className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors text-left ${
                activeMenu === 'courses'
                  ? 'bg-blue-600 text-white'
                  : 'text-gray-700 hover:bg-gray-100'
              }`}
            >
              <BookOpen className="w-5 h-5" />
              <span>담당과목</span>
            </button>
            <button
              onClick={() => setActiveMenu('create-course')}
              className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors text-left ${
                activeMenu === 'create-course'
                  ? 'bg-blue-600 text-white'
                  : 'text-gray-700 hover:bg-gray-100'
              }`}
            >
              <FolderPlus className="w-5 h-5" />
              <span>과정개설</span>
            </button>
            
            {/* 콘텐츠 라이브러리 - 하위 메뉴 포함 */}
            <div>
              <button
                onClick={handleContentLibraryClick}
                className={`w-full flex items-center justify-between px-4 py-3 rounded-lg transition-colors text-left ${
                  isContentLibrarySubMenu
                    ? 'bg-blue-600 text-white'
                    : 'text-gray-700 hover:bg-gray-100'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Library className="w-5 h-5" />
                  <span>콘텐츠 라이브러리</span>
                </div>
                {contentLibraryExpanded ? (
                  <ChevronDown className="w-4 h-4" />
                ) : (
                  <ChevronRight className="w-4 h-4" />
                )}
              </button>
              
              {/* 하위 메뉴 */}
              {contentLibraryExpanded && (
                <div className="ml-4 mt-1 flex flex-col gap-1">
                  <button
                    onClick={() => setActiveMenu('content-all')}
                    className={`flex items-center gap-3 px-4 py-2 rounded-lg transition-colors text-left text-sm ${
                      activeMenu === 'content-all'
                        ? 'bg-blue-100 text-blue-700 font-medium'
                        : 'text-gray-600 hover:bg-gray-100'
                    }`}
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-current"></span>
                    <span>전체 콘텐츠</span>
                  </button>
                  <button
                    onClick={() => setActiveMenu('content-favorites')}
                    className={`flex items-center gap-3 px-4 py-2 rounded-lg transition-colors text-left text-sm ${
                      activeMenu === 'content-favorites'
                        ? 'bg-blue-100 text-blue-700 font-medium'
                        : 'text-gray-600 hover:bg-gray-100'
                    }`}
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-current"></span>
                    <span>찜한 콘텐츠</span>
                  </button>
                </div>
              )}
            </div>

            {/* 시험관리 - 하위 메뉴 포함 */}
            <div>
              <button
                onClick={handleExamMenuClick}
                className={`w-full flex items-center justify-between px-4 py-3 rounded-lg transition-colors text-left ${
                  isExamSubMenu
                    ? 'bg-blue-600 text-white'
                    : 'text-gray-700 hover:bg-gray-100'
                }`}
              >
                <div className="flex items-center gap-3">
                  <ClipboardList className="w-5 h-5" />
                  <span>시험관리</span>
                </div>
                {examMenuExpanded ? (
                  <ChevronDown className="w-4 h-4" />
                ) : (
                  <ChevronRight className="w-4 h-4" />
                )}
              </button>
              
              {/* 시험관리 하위 메뉴 */}
              {examMenuExpanded && (
                <div className="ml-4 mt-1 flex flex-col gap-1">
                  <button
                    onClick={() => setActiveMenu('exam-categories')}
                    className={`flex items-center gap-3 px-4 py-2 rounded-lg transition-colors text-left text-sm ${
                      activeMenu === 'exam-categories'
                        ? 'bg-blue-100 text-blue-700 font-medium'
                        : 'text-gray-600 hover:bg-gray-100'
                    }`}
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-current"></span>
                    <span>문제카테고리</span>
                  </button>
                  <button
                    onClick={() => setActiveMenu('exam-questions')}
                    className={`flex items-center gap-3 px-4 py-2 rounded-lg transition-colors text-left text-sm ${
                      activeMenu === 'exam-questions'
                        ? 'bg-blue-100 text-blue-700 font-medium'
                        : 'text-gray-600 hover:bg-gray-100'
                    }`}
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-current"></span>
                    <span>문제은행</span>
                  </button>
                  <button
                    onClick={() => setActiveMenu('exam-management')}
                    className={`flex items-center gap-3 px-4 py-2 rounded-lg transition-colors text-left text-sm ${
                      activeMenu === 'exam-management'
                        ? 'bg-blue-100 text-blue-700 font-medium'
                        : 'text-gray-600 hover:bg-gray-100'
                    }`}
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-current"></span>
                    <span>시험관리</span>
                  </button>
                </div>
              )}
            </div>
          </nav>
        </aside>

        {/* Sidebar Spacer - Fixed 사이드바를 위한 공간 확보 */}
        <div className="w-64 flex-shrink-0"></div>

        {/* Main Content Area */}
        <main className="flex-1 p-8">
          <div className="max-w-7xl mx-auto">
            {/* Empty content area - 추후 추가될 컨텐츠 영역 */}
            {activeMenu === 'dashboard' ? (
              <Dashboard key={refreshKey} onNavigate={(menu) => setActiveMenu(menu)} />
            ) : activeMenu === 'explore' ? (
              <CourseExplorer key={refreshKey} />
            ) : activeMenu === 'courses' ? (
              <MyCoursesList key={refreshKey} />
            ) : activeMenu === 'create-course' ? (
              <CreateCourseForm key={refreshKey} onCreated={() => setActiveMenu('explore')} />
            ) : activeMenu === 'content-all' ? (
              <ContentLibraryPage key={refreshKey} activeTab="all" />
            ) : activeMenu === 'content-favorites' ? (
              <ContentLibraryPage key={`${refreshKey}-fav`} activeTab="favorites" />
            ) : activeMenu === 'exam-categories' ? (
              <QuestionCategoryPage key={refreshKey} />
            ) : activeMenu === 'exam-questions' ? (
              <QuestionBankPage key={refreshKey} />
            ) : activeMenu === 'exam-management' ? (
              <ExamManagementPage key={refreshKey} />
            ) : (
              <div className="bg-white rounded-lg border-2 border-dashed border-gray-300 p-16 text-center">
                <div className="text-gray-400">
                  <GraduationCap className="w-16 h-16 mx-auto mb-4 opacity-50" />
                  <p className="text-lg">컨텐츠 영역</p>
                  <p className="text-sm mt-2">메뉴를 선택하면 관련 내용이 표시됩니다</p>
                </div>
              </div>
            )}
          </div>
        </main>
      </div>
    </div>
  );
}

