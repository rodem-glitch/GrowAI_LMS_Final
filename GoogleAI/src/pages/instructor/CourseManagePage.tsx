// pages/instructor/CourseManagePage.tsx — 교수자 강좌 관리
import { useState } from 'react';
import { Link } from 'react-router-dom';
import {
  BookOpen, Users, BarChart3, Settings, FileText,
  ClipboardCheck, Plus, Edit3, Eye,
} from 'lucide-react';
import ProgressBar from '@/components/common/ProgressBar';

const courses = [
  {
    code: 'CS101', name: 'Python 프로그래밍 기초', semester: '2026-1',
    students: 45, avgProgress: 72, avgGrade: 82, status: 'active',
    weeklyContent: 15, currentWeek: 5,
  },
  {
    code: 'CS201', name: '데이터베이스 설계', semester: '2026-1',
    students: 38, avgProgress: 58, avgGrade: 76, status: 'active',
    weeklyContent: 15, currentWeek: 4,
  },
  {
    code: 'AI301', name: 'AI 머신러닝 입문', semester: '2026-1',
    students: 43, avgProgress: 41, avgGrade: 79, status: 'active',
    weeklyContent: 15, currentWeek: 3,
  },
];

export default function CourseManagePage() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">강좌 관리</h1>
          <p className="text-sm text-content-secondary mt-1">담당 강좌 운영 및 설정</p>
        </div>
      </div>

      <div className="space-y-4">
        {courses.map((c) => (
          <div key={c.code} className="card">
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-xl bg-primary-50 flex items-center justify-center">
                  <BookOpen className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <h2 className="text-base font-semibold text-gray-900 dark:text-white">{c.name}</h2>
                  <p className="text-xs text-content-muted">{c.code} | {c.semester} | 수강생 {c.students}명</p>
                </div>
              </div>
              <span className="badge badge-success">운영중</span>
            </div>

            {/* Stats Row */}
            <div className="grid grid-cols-4 gap-4 mb-4">
              <div className="card-muted text-center">
                <div className="text-sm font-bold text-gray-900 dark:text-white">{c.students}</div>
                <div className="text-[10px] text-gray-500">수강생</div>
              </div>
              <div className="card-muted text-center">
                <div className="text-sm font-bold text-gray-900 dark:text-white">{c.avgProgress}%</div>
                <div className="text-[10px] text-gray-500">평균 진도율</div>
              </div>
              <div className="card-muted text-center">
                <div className="text-sm font-bold text-gray-900 dark:text-white">{c.avgGrade}</div>
                <div className="text-[10px] text-gray-500">평균 성적</div>
              </div>
              <div className="card-muted text-center">
                <div className="text-sm font-bold text-gray-900 dark:text-white">{c.currentWeek}/{c.weeklyContent}</div>
                <div className="text-[10px] text-gray-500">진행 주차</div>
              </div>
            </div>

            <ProgressBar value={(c.currentWeek / c.weeklyContent) * 100} label="강좌 진행률" size="sm" variant="success" />

            {/* Actions */}
            <div className="flex items-center gap-2 mt-4">
              <button className="btn btn-sm bg-primary-50 text-primary-700 hover:bg-primary-100">
                <Users className="w-3 h-3" /> 수강생 관리
              </button>
              <button className="btn btn-sm bg-gray-50 text-gray-700 hover:bg-gray-100">
                <ClipboardCheck className="w-3 h-3" /> 성적 관리
              </button>
              <button className="btn btn-sm bg-gray-50 text-gray-700 hover:bg-gray-100">
                <FileText className="w-3 h-3" /> 강좌 계획서
              </button>
              <button className="btn btn-sm bg-gray-50 text-gray-700 hover:bg-gray-100">
                <Settings className="w-3 h-3" /> 설정
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
