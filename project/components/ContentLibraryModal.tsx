import React, { useState } from 'react';
import { X, Search, Heart } from 'lucide-react';

interface Content {
  id: string;
  title: string;
  description: string;
  category: string;
  tags: string[];
  views: number;
  thumbnail: string;
  isFavorite: boolean;
  duration?: string;
}

interface ContentLibraryModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (content: Content) => void;
}

export function ContentLibraryModal({ isOpen, onClose, onSelect }: ContentLibraryModalProps) {
  const [activeTab, setActiveTab] = useState<'all' | 'favorites'>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('전체');
  const [levelFilter, setLevelFilter] = useState('전체 유형');
  const [onlyFree, setOnlyFree] = useState(false);

  // 샘플 콘텐츠 데이터
  const contents: Content[] = [
    {
      id: '1',
      title: 'Python 기초 문법 완전정복',
      description: 'Python의 기본 문법부터 변수, 함수와 제어문까지 완벽 이해 및 실습 경험입니다.',
      category: 'IT/프로그래밍',
      tags: ['Python', '기초', '문법'],
      views: 1250,
      thumbnail: 'https://images.unsplash.com/photo-1515879218367-8466d910aaa4?w=400&h=300&fit=crop',
      isFavorite: true,
      duration: '4시간',
    },
    {
      id: '2',
      title: '데이터베이스 설계 원리',
      description: '관계형 데이터베이스 설계와 핵심 원리 및 관계형 모델을 교육받을 수 있습니다.',
      category: '데이터',
      tags: ['Database', 'SQL', '설계'],
      views: 890,
      thumbnail: 'https://images.unsplash.com/photo-1544383835-bda2bc66a55d?w=400&h=300&fit=crop',
      isFavorite: false,
      duration: '5시간',
    },
    {
      id: '3',
      title: 'AI 머신러닝 실습 가이드',
      description: '실제 데이터를 활용한 머신러닝 전체 과정을 실습 가이드 모델로 학습합니다.',
      category: 'AI',
      tags: ['AI', '머신러닝', '실습'],
      views: 2150,
      thumbnail: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=400&h=300&fit=crop',
      isFavorite: true,
      duration: '3시간',
    },
    {
      id: '4',
      title: '웹 프론트엔드 개발 실무',
      description: 'HTML, CSS, JavaScript를 활용한 실무 웹 개발 프로젝트',
      category: 'IT/프로그래밍',
      tags: ['Frontend', 'Web', 'JavaScript'],
      views: 1670,
      thumbnail: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=400&h=300&fit=crop',
      isFavorite: false,
      duration: '6시간',
    },
    {
      id: '5',
      title: '데이터 시각화 기초',
      description: '차트와 그래프를 활용한 효과적인 데이터 시각화 기법',
      category: '데이터',
      tags: ['Data', 'Visualization', 'Chart'],
      views: 1320,
      thumbnail: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&h=300&fit=crop',
      isFavorite: false,
      duration: '4시간',
    },
    {
      id: '6',
      title: 'UI/UX 디자인 원칙',
      description: '사용자 중심의 인터페이스 디자인 원칙과 실전 적용',
      category: '디자인',
      tags: ['UI', 'UX', '디자인'],
      views: 980,
      thumbnail: 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=400&h=300&fit=crop',
      isFavorite: true,
      duration: '5시간',
    },
  ];

  const filteredContents = contents.filter((content) => {
    const matchesTab = activeTab === 'all' || (activeTab === 'favorites' && content.isFavorite);
    const matchesSearch = content.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      content.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = categoryFilter === '전체' || content.category === categoryFilter;
    
    return matchesTab && matchesSearch && matchesCategory;
  });

  const handleSelect = (content: Content) => {
    onSelect(content);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-5xl w-full max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-gray-900">콘텐츠 라이브러리</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6">
          {/* Subtitle */}
          <div className="mb-6">
            <h3 className="text-gray-900 mb-2">올리팩 콘텐츠 라이브러리</h3>
            <p className="text-sm text-gray-600">
              플러에서 보유한 다양한 교육 콘텐츠를 검색하고 과정에 활용하세요.
            </p>
          </div>

          {/* Tabs */}
          <div className="flex gap-6 mb-6 border-b border-gray-200">
            <button
              onClick={() => setActiveTab('all')}
              className={`pb-3 border-b-2 transition-colors ${
                activeTab === 'all'
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-600 hover:text-gray-900'
              }`}
            >
              전체 콘텐츠
            </button>
            <button
              onClick={() => setActiveTab('favorites')}
              className={`pb-3 border-b-2 transition-colors ${
                activeTab === 'favorites'
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-600 hover:text-gray-900'
              }`}
            >
              찜한 콘텐츠 ({contents.filter(c => c.isFavorite).length})
            </button>
          </div>

          {/* Filters */}
          <div className="flex items-center gap-4 mb-6">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="콘텐츠 제목이나 태그로 검색..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option>전체</option>
              <option>IT/프로그래밍</option>
              <option>데이터</option>
              <option>AI</option>
              <option>디자인</option>
            </select>
            <select
              value={levelFilter}
              onChange={(e) => setLevelFilter(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option>전체 유형</option>
              <option>기초</option>
              <option>중급</option>
              <option>고급</option>
            </select>
            <label className="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
              <input
                type="checkbox"
                checked={onlyFree}
                onChange={(e) => setOnlyFree(e.target.checked)}
                className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
              />
              무료
            </label>
            <div className="text-sm text-blue-600 cursor-pointer hover:underline">
              총 {filteredContents.length}개의 콘텐츠
            </div>
          </div>

          {/* Content Grid */}
          <div className="grid grid-cols-3 gap-6">
            {filteredContents.map((content) => (
              <div
                key={content.id}
                className="group cursor-pointer border border-gray-200 rounded-lg overflow-hidden hover:shadow-lg transition-shadow"
                onClick={() => handleSelect(content)}
              >
                {/* Thumbnail */}
                <div className="relative h-48 bg-gray-100">
                  <img
                    src={content.thumbnail}
                    alt={content.title}
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute top-2 left-2 bg-white px-2 py-1 rounded text-xs">
                    {content.isFavorite ? '찜함' : '콘텐츠'}
                  </div>
                  <button className="absolute top-2 right-2 w-8 h-8 bg-white rounded-full flex items-center justify-center hover:bg-gray-50 transition-colors">
                    <Heart
                      className={`w-4 h-4 ${
                        content.isFavorite ? 'fill-red-500 text-red-500' : 'text-gray-400'
                      }`}
                    />
                  </button>
                  {content.duration && (
                    <div className="absolute bottom-2 right-2 bg-black bg-opacity-75 text-white px-2 py-1 rounded text-xs">
                      {content.duration}
                    </div>
                  )}
                </div>

                {/* Content Info */}
                <div className="p-4">
                  <div className="text-xs text-blue-600 mb-1">{content.category}</div>
                  <h4 className="text-gray-900 mb-2 line-clamp-1">{content.title}</h4>
                  <p className="text-sm text-gray-600 mb-3 line-clamp-2">{content.description}</p>
                  
                  {/* Tags */}
                  <div className="flex flex-wrap gap-1 mb-3">
                    {content.tags.map((tag) => (
                      <span
                        key={tag}
                        className="px-2 py-0.5 bg-gray-100 text-gray-700 rounded text-xs"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>

                  {/* Stats */}
                  <div className="flex items-center justify-between text-xs text-gray-500">
                    <div className="flex items-center gap-1">
                      <span>👁️ {content.views.toLocaleString()}</span>
                    </div>
                    <button className="text-blue-600 hover:underline">
                      과정에 추가
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {filteredContents.length === 0 && (
            <div className="text-center py-16 text-gray-500">
              <p className="mb-2">검색 결과가 없습니다.</p>
              <p className="text-sm">다른 검색어나 필터를 시도해보세요.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
