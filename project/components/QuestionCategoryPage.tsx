import { useState, useEffect } from 'react';
import { Plus, Edit, Trash2, FolderTree, ChevronRight, ChevronDown, Save, X } from 'lucide-react';

// 문제 카테고리 타입
export interface QuestionCategory {
  id: string;
  name: string;
  parentId: string | null;
  children?: QuestionCategory[];
  createdAt: string;
}

const STORAGE_KEY = 'tutor_question_categories';

// 로컬스토리지에서 데이터 로드
const loadCategories = (): QuestionCategory[] => {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    return saved ? JSON.parse(saved) : [];
  } catch {
    return [];
  }
};

// 로컬스토리지에 데이터 저장
const saveCategories = (categories: QuestionCategory[]) => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(categories));
};

// 플랫 목록을 트리 구조로 변환
const buildTree = (categories: QuestionCategory[]): QuestionCategory[] => {
  const map = new Map<string, QuestionCategory>();
  const roots: QuestionCategory[] = [];

  categories.forEach(cat => {
    map.set(cat.id, { ...cat, children: [] });
  });

  categories.forEach(cat => {
    const node = map.get(cat.id)!;
    if (cat.parentId && map.has(cat.parentId)) {
      map.get(cat.parentId)!.children!.push(node);
    } else {
      roots.push(node);
    }
  });

  return roots;
};

export function QuestionCategoryPage() {
  const [categories, setCategories] = useState<QuestionCategory[]>(() => loadCategories());
  const [expandedIds, setExpandedIds] = useState<Set<string>>(new Set());
  
  // 추가/편집 모달 상태
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<QuestionCategory | null>(null);
  const [newName, setNewName] = useState('');
  const [selectedParentId, setSelectedParentId] = useState<string | null>(null);

  // 저장
  useEffect(() => {
    saveCategories(categories);
  }, [categories]);

  const tree = buildTree(categories);

  const toggleExpand = (id: string) => {
    setExpandedIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const openAddModal = (parentId: string | null = null) => {
    setEditingCategory(null);
    setNewName('');
    setSelectedParentId(parentId);
    setIsModalOpen(true);
  };

  const openEditModal = (category: QuestionCategory) => {
    setEditingCategory(category);
    setNewName(category.name);
    setSelectedParentId(category.parentId);
    setIsModalOpen(true);
  };

  const handleSave = () => {
    if (!newName.trim()) return;

    if (editingCategory) {
      // 수정
      setCategories(prev =>
        prev.map(c =>
          c.id === editingCategory.id
            ? { ...c, name: newName.trim(), parentId: selectedParentId }
            : c
        )
      );
    } else {
      // 추가
      const newCategory: QuestionCategory = {
        id: `cat_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        name: newName.trim(),
        parentId: selectedParentId,
        createdAt: new Date().toISOString(),
      };
      setCategories(prev => [...prev, newCategory]);
    }

    setIsModalOpen(false);
    setEditingCategory(null);
    setNewName('');
  };

  const handleDelete = (id: string) => {
    // 하위 카테고리가 있는지 확인
    const hasChildren = categories.some(c => c.parentId === id);
    if (hasChildren) {
      alert('하위 카테고리가 있어 삭제할 수 없습니다.');
      return;
    }
    if (!confirm('이 카테고리를 삭제하시겠습니까?')) return;
    setCategories(prev => prev.filter(c => c.id !== id));
  };

  // 카테고리 트리 렌더링
  const renderCategory = (category: QuestionCategory, depth: number = 0) => {
    const isExpanded = expandedIds.has(category.id);
    const hasChildren = category.children && category.children.length > 0;

    return (
      <div key={category.id}>
        <div
          className={`flex items-center gap-2 px-4 py-3 hover:bg-gray-50 border-b border-gray-100 ${
            depth > 0 ? 'bg-gray-50/50' : ''
          }`}
          style={{ paddingLeft: `${16 + depth * 24}px` }}
        >
          {hasChildren ? (
            <button
              onClick={() => toggleExpand(category.id)}
              className="p-1 hover:bg-gray-200 rounded"
            >
              {isExpanded ? (
                <ChevronDown className="w-4 h-4 text-gray-500" />
              ) : (
                <ChevronRight className="w-4 h-4 text-gray-500" />
              )}
            </button>
          ) : (
            <span className="w-6" />
          )}
          
          <FolderTree className="w-4 h-4 text-indigo-500" />
          <span className="flex-1 text-gray-800">{category.name}</span>
          
          <button
            onClick={() => openAddModal(category.id)}
            className="p-1.5 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded transition-colors"
            title="하위 카테고리 추가"
          >
            <Plus className="w-4 h-4" />
          </button>
          <button
            onClick={() => openEditModal(category)}
            className="p-1.5 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded transition-colors"
            title="수정"
          >
            <Edit className="w-4 h-4" />
          </button>
          <button
            onClick={() => handleDelete(category.id)}
            className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded transition-colors"
            title="삭제"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>

        {isExpanded && hasChildren && (
          <div>
            {category.children!.map(child => renderCategory(child, depth + 1))}
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">문제 카테고리</h2>
          <p className="text-gray-500 mt-1">문제를 분류할 카테고리를 관리합니다.</p>
        </div>
        <button
          onClick={() => openAddModal(null)}
          className="flex items-center gap-2 px-4 py-2.5 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
        >
          <Plus className="w-5 h-5" />
          <span>카테고리 추가</span>
        </button>
      </div>

      {/* 카테고리 목록 */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
        {tree.length > 0 ? (
          <div>
            {tree.map(category => renderCategory(category))}
          </div>
        ) : (
          <div className="text-center py-16 text-gray-400">
            <FolderTree className="w-12 h-12 mx-auto mb-4 opacity-50" />
            <p>등록된 카테고리가 없습니다.</p>
            <button
              onClick={() => openAddModal(null)}
              className="mt-4 text-indigo-600 hover:underline"
            >
              + 첫 번째 카테고리 추가하기
            </button>
          </div>
        )}
      </div>

      {/* 추가/수정 모달 */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/50" onClick={() => setIsModalOpen(false)} />
          <div className="relative bg-white rounded-xl shadow-2xl w-full max-w-md mx-4 p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-semibold text-gray-900">
                {editingCategory ? '카테고리 수정' : '카테고리 추가'}
              </h3>
              <button
                onClick={() => setIsModalOpen(false)}
                className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  카테고리명 <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  placeholder="카테고리명을 입력하세요"
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  autoFocus
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  상위 카테고리
                </label>
                <select
                  value={selectedParentId || ''}
                  onChange={(e) => setSelectedParentId(e.target.value || null)}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <option value="">없음 (최상위)</option>
                  {categories
                    .filter(c => c.id !== editingCategory?.id)
                    .map(c => (
                      <option key={c.id} value={c.id}>{c.name}</option>
                    ))}
                </select>
              </div>
            </div>

            <div className="flex gap-3 mt-6">
              <button
                onClick={() => setIsModalOpen(false)}
                className="flex-1 px-4 py-2.5 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              >
                취소
              </button>
              <button
                onClick={handleSave}
                disabled={!newName.trim()}
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
