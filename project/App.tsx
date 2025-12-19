import { useState } from 'react';
import { GraduationCap, BookOpen, FolderPlus, FileText, Compass, ChevronDown, ChevronRight } from 'lucide-react';
import { CreateCourseForm } from './components/CreateCourseForm';
import { MyCoursesList } from './components/MyCoursesList';
import { CreateSubjectWizard } from './components/CreateSubjectWizard';
import { CourseExplorer } from './components/CourseExplorer';
import { Dashboard } from './components/Dashboard';

export default function App() {
  const [activeMenu, setActiveMenu] = useState<string>('dashboard');
  const [exploreExpanded, setExploreExpanded] = useState(false);

  // 과정탐색 하위 메뉴 여부 확인
  const isExploreSubMenu = activeMenu === 'explore-haksa' || activeMenu === 'explore-plism';

  const handleExploreClick = () => {
    // 과정탐색 클릭 시 펼침/접힘 토글 및 학사를 디폴트로 선택
    if (!exploreExpanded) {
      setExploreExpanded(true);
      setActiveMenu('explore-haksa');
    } else {
      setExploreExpanded(!exploreExpanded);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-50">
        <div className="px-8 py-4">
          <div className="flex items-center">
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
          </div>
        </div>
      </header>

      <div className="flex">
        {/* Left Navigation Sidebar */}
        <aside className="w-64 bg-white border-r border-gray-200 sticky top-[88px] h-[calc(100vh-88px)] overflow-y-auto">
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
            
            {/* 과정탐색 - 하위 메뉴 포함 */}
            <div>
              <button
                onClick={handleExploreClick}
                className={`w-full flex items-center justify-between px-4 py-3 rounded-lg transition-colors text-left ${
                  isExploreSubMenu
                    ? 'bg-blue-600 text-white'
                    : 'text-gray-700 hover:bg-gray-100'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Compass className="w-5 h-5" />
                  <span>과정탐색</span>
                </div>
                {exploreExpanded ? (
                  <ChevronDown className="w-4 h-4" />
                ) : (
                  <ChevronRight className="w-4 h-4" />
                )}
              </button>
              
              {/* 하위 메뉴 */}
              {exploreExpanded && (
                <div className="ml-4 mt-1 flex flex-col gap-1">
                  <button
                    onClick={() => setActiveMenu('explore-haksa')}
                    className={`flex items-center gap-3 px-4 py-2 rounded-lg transition-colors text-left text-sm ${
                      activeMenu === 'explore-haksa'
                        ? 'bg-blue-100 text-blue-700 font-medium'
                        : 'text-gray-600 hover:bg-gray-100'
                    }`}
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-current"></span>
                    <span>학사</span>
                  </button>
                  <button
                    onClick={() => setActiveMenu('explore-plism')}
                    className={`flex items-center gap-3 px-4 py-2 rounded-lg transition-colors text-left text-sm ${
                      activeMenu === 'explore-plism'
                        ? 'bg-blue-100 text-blue-700 font-medium'
                        : 'text-gray-600 hover:bg-gray-100'
                    }`}
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-current"></span>
                    <span>PLISM</span>
                  </button>
                </div>
              )}
            </div>
            
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
            <button
              onClick={() => setActiveMenu('create-subject')}
              className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors text-left ${
                activeMenu === 'create-subject'
                  ? 'bg-blue-600 text-white'
                  : 'text-gray-700 hover:bg-gray-100'
              }`}
            >
              <FileText className="w-5 h-5" />
              <span>과목개설</span>
            </button>
          </nav>
        </aside>

        {/* Main Content Area */}
        <main className="flex-1 p-8">
          <div className="max-w-7xl mx-auto">
            {/* Empty content area - 추후 추가될 컨텐츠 영역 */}
            {activeMenu === 'dashboard' ? (
              <Dashboard onNavigate={(menu) => setActiveMenu(menu)} />
            ) : activeMenu === 'explore-haksa' ? (
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-16 text-center">
                <div className="text-gray-400">
                  <Compass className="w-16 h-16 mx-auto mb-4 opacity-50" />
                  <p className="text-lg font-medium text-gray-600">학사 과정탐색</p>
                  <p className="text-sm mt-2">추후 생성 예정입니다.</p>
                </div>
              </div>
            ) : activeMenu === 'explore-plism' ? (
              <CourseExplorer />
            ) : activeMenu === 'courses' ? (
              <MyCoursesList />
            ) : activeMenu === 'create-course' ? (
              <CreateCourseForm />
            ) : activeMenu === 'create-subject' ? (
              <CreateSubjectWizard />
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
