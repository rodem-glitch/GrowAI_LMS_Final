// pages/admin/RecommendationEnginePage.tsx — Apache PredictionIO 추천 엔진 대시보드
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Brain, Zap, Target, TrendingUp, RefreshCw, BookOpen, Users, BarChart3, Star, Tag, Activity } from 'lucide-react';
import { recommendationApi } from '@/services/api';

export default function RecommendationEnginePage() {
  const [userId, setUserId] = useState(1);
  const [category, setCategory] = useState('');
  const [limit, setLimit] = useState(10);

  const { data: dashboard, isLoading: loadingDash } = useQuery({
    queryKey: ['recommendation-dashboard'],
    queryFn: () => recommendationApi.dashboard().then(r => r.data.data),
  });

  const { data: courses, isLoading: loadingCourses, refetch } = useQuery({
    queryKey: ['recommendation-courses', userId, limit, category],
    queryFn: () => recommendationApi.courses(userId, limit, category).then(r => r.data.data),
  });

  const { data: contents } = useQuery({
    queryKey: ['recommendation-contents', userId],
    queryFn: () => recommendationApi.contents(userId).then(r => r.data.data),
  });

  const { data: trainingStatus } = useQuery({
    queryKey: ['recommendation-training'],
    queryFn: () => recommendationApi.trainingStatus().then(r => r.data.data),
  });

  const statusColor = (s: string) =>
    s === 'READY' ? 'text-green-400' : s === 'TRAINING' ? 'text-yellow-400' : s === 'STANDALONE' ? 'text-blue-400' : 'text-red-400';

  return (
    <div className="space-y-6">
      {/* 헤더 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-2">
            <Brain className="w-7 h-7 text-purple-400" />
            개인 맞춤형 추천 엔진 (Apache PredictionIO)
          </h1>
          <p className="text-gray-400 mt-1">교육 이력 기반 협업 필터링 + 콘텐츠 추천</p>
        </div>
        <button onClick={() => refetch()} className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700">
          <RefreshCw className="w-4 h-4" /> 새로고침
        </button>
      </div>

      {/* 엔진 상태 + KPI */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        {trainingStatus && (
          <div className="bg-gray-800 rounded-xl p-4 border border-gray-700">
            <div className="flex items-center gap-2 mb-2">
              <Activity className="w-5 h-5 text-purple-400" />
              <span className="text-gray-400 text-sm">엔진 상태</span>
            </div>
            <p className={`text-xl font-bold ${statusColor(trainingStatus.status)}`}>{trainingStatus.status}</p>
            <p className="text-xs text-gray-500 mt-1">v{trainingStatus.version} | 정확도 {(trainingStatus.modelAccuracy * 100).toFixed(1)}%</p>
          </div>
        )}
        {[
          { icon: Users, label: '총 사용자', value: trainingStatus?.totalUsers || 0, color: 'text-blue-400' },
          { icon: BookOpen, label: '총 아이템', value: trainingStatus?.totalItems || 0, color: 'text-green-400' },
          { icon: Zap, label: '총 이벤트', value: trainingStatus?.totalEvents || 0, color: 'text-yellow-400' },
          { icon: Target, label: 'CTR', value: dashboard ? (dashboard.avgClickThroughRate * 100).toFixed(1) + '%' : '-', color: 'text-pink-400' },
        ].map((kpi, i) => (
          <div key={i} className="bg-gray-800 rounded-xl p-4 border border-gray-700">
            <div className="flex items-center gap-2 mb-2">
              <kpi.icon className={`w-5 h-5 ${kpi.color}`} />
              <span className="text-gray-400 text-sm">{kpi.label}</span>
            </div>
            <p className="text-xl font-bold text-white">{kpi.value}</p>
          </div>
        ))}
      </div>

      {/* 추천 결과 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-gray-800 rounded-xl p-5 border border-gray-700">
          <h2 className="text-lg font-semibold text-white flex items-center gap-2 mb-4">
            <Star className="w-5 h-5 text-yellow-400" />
            맞춤 강좌 추천 (userId: {userId})
          </h2>
          <div className="flex items-center gap-3 mb-4">
            <input type="number" value={userId} onChange={e => setUserId(Number(e.target.value))}
              className="w-20 px-3 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm" placeholder="userId" />
            <select value={category} onChange={e => setCategory(e.target.value)}
              className="px-3 py-1.5 bg-gray-700 border border-gray-600 rounded-lg text-white text-sm">
              <option value="">전체 카테고리</option>
              <option value="programming">프로그래밍</option>
              <option value="ai">AI/ML</option>
              <option value="cloud">클라우드</option>
            </select>
          </div>
          {loadingCourses ? (
            <p className="text-gray-500 text-sm">로딩 중...</p>
          ) : courses && courses.length > 0 ? (
            <div className="space-y-2">
              {courses.map((c: any, i: number) => (
                <div key={i} className="flex items-center justify-between p-3 bg-gray-750 rounded-lg border border-gray-700/50">
                  <div>
                    <p className="text-sm text-white font-medium">{c.title || c.courseName || `강좌 #${c.courseId}`}</p>
                    <p className="text-xs text-gray-400">{c.category || '일반'} · 신뢰도 {((c.confidence || c.score || 0) * 100).toFixed(0)}%</p>
                  </div>
                  <TrendingUp className="w-4 h-4 text-green-400" />
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500 text-sm">추천 데이터 없음</p>
          )}
        </div>

        <div className="bg-gray-800 rounded-xl p-5 border border-gray-700">
          <h2 className="text-lg font-semibold text-white flex items-center gap-2 mb-4">
            <Tag className="w-5 h-5 text-blue-400" />
            콘텐츠 기반 추천
          </h2>
          {contents && contents.length > 0 ? (
            <div className="space-y-2">
              {contents.map((c: any, i: number) => (
                <div key={i} className="flex items-center justify-between p-3 bg-gray-750 rounded-lg border border-gray-700/50">
                  <div>
                    <p className="text-sm text-white font-medium">{c.title || `콘텐츠 #${c.contentId}`}</p>
                    <p className="text-xs text-gray-400">{c.type || '일반'} · 유사도 {((c.similarity || 0) * 100).toFixed(0)}%</p>
                  </div>
                  <BarChart3 className="w-4 h-4 text-purple-400" />
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500 text-sm">콘텐츠 추천 데이터 없음</p>
          )}
        </div>
      </div>

      {/* 대시보드 요약 */}
      {dashboard && (
        <div className="bg-gray-800 rounded-xl p-5 border border-gray-700">
          <h2 className="text-lg font-semibold text-white mb-3">추천 엔진 성과 요약</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
            <div><p className="text-2xl font-bold text-green-400">{dashboard.totalRecommendations?.toLocaleString() || 0}</p><p className="text-xs text-gray-400">총 추천 수</p></div>
            <div><p className="text-2xl font-bold text-blue-400">{dashboard.totalClicks?.toLocaleString() || 0}</p><p className="text-xs text-gray-400">총 클릭 수</p></div>
            <div><p className="text-2xl font-bold text-yellow-400">{((dashboard.avgClickThroughRate || 0) * 100).toFixed(1)}%</p><p className="text-xs text-gray-400">평균 CTR</p></div>
            <div><p className="text-2xl font-bold text-purple-400">{((dashboard.avgSatisfaction || 0) * 100).toFixed(1)}%</p><p className="text-xs text-gray-400">만족도</p></div>
          </div>
        </div>
      )}
    </div>
  );
}
