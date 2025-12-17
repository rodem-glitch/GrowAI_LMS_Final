import React, { useEffect, useMemo, useState } from 'react';
import { ChevronDown, ChevronRight, Edit, Plus, Trash2 } from 'lucide-react';
import { tutorLmsApi, TutorCurriculumRow } from '../../api/tutorLmsApi';
import { SessionEditModal } from '../SessionEditModal';

type CurriculumLesson = {
  lessonId: number;
  chapter: number;
  lessonName: string;
  duration: string;
};

type CurriculumSession = {
  sectionId: number;
  sectionName: string;
  lessons: CurriculumLesson[];
  sortKey: number;
};

function isNumericId(value: string) {
  const trimmed = value.trim();
  if (!trimmed) return false;
  return /^\d+$/.test(trimmed);
}

function groupCurriculum(rows: TutorCurriculumRow[]): CurriculumSession[] {
  const map = new Map<number, CurriculumSession>();

  rows.forEach((row) => {
    const sectionId = Number(row.section_id ?? 0);
    const sectionName = (row.section_nm || '기본').trim() || '기본';
    const lessonId = Number(row.lesson_id);
    const chapter = Number(row.chapter ?? 0);
    const lessonName = (row.lesson_nm || '').trim() || `레슨 ${lessonId}`;
    const duration = row.duration_conv || '-';

    if (!map.has(sectionId)) {
      map.set(sectionId, {
        sectionId,
        sectionName,
        lessons: [],
        sortKey: chapter || Number.MAX_SAFE_INTEGER,
      });
    }

    const session = map.get(sectionId)!;
    session.sectionName = sectionName;
    session.sortKey = Math.min(session.sortKey, chapter || Number.MAX_SAFE_INTEGER);
    session.lessons.push({ lessonId, chapter, lessonName, duration });
  });

  return Array.from(map.values())
    .map((session) => ({
      ...session,
      lessons: session.lessons.sort((a, b) => a.chapter - b.chapter),
    }))
    .sort((a, b) => a.sortKey - b.sortKey);
}

export function CurriculumTab({ courseId }: { courseId: number }) {
  if (!courseId || Number.isNaN(courseId)) {
    return <div className="text-sm text-red-600">과목 ID가 올바르지 않습니다.</div>;
  }

  const [rows, setRows] = useState<TutorCurriculumRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [expandedSectionId, setExpandedSectionId] = useState<number | null>(null);
  const [createModalOpen, setCreateModalOpen] = useState(false);

  const sessions = useMemo(() => groupCurriculum(rows), [rows]);

  const refresh = async () => {
    setLoading(true);
    setErrorMessage(null);
    try {
      const res = await tutorLmsApi.getCurriculum({ courseId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);
      setRows(res.rst_data ?? []);
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : '강의목차를 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let cancelled = false;

    // 왜: 탭을 처음 열었을 때 바로 DB 데이터를 가져와야 새로고침해도 동일한 화면이 됩니다.
    const run = async () => {
      setLoading(true);
      setErrorMessage(null);
      try {
        const res = await tutorLmsApi.getCurriculum({ courseId });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);
        if (!cancelled) setRows(res.rst_data ?? []);
      } catch (e) {
        if (!cancelled) setErrorMessage(e instanceof Error ? e.message : '강의목차를 불러오는 중 오류가 발생했습니다.');
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    run();
    return () => {
      cancelled = true;
    };
  }, [courseId]);

  const toggleSection = (sectionId: number) => {
    setExpandedSectionId(expandedSectionId === sectionId ? null : sectionId);
  };

  const handleCreateSession = async (session: { title: string; videos: { title: string; url: string }[] }) => {
    // 왜: "차시"는 DB에서는 섹션(LM_COURSE_SECTION)이고, 그 안의 영상은 레슨(LM_LESSON) 연결(LM_COURSE_LESSON)입니다.
    const sectionName = (session.title || '').trim();
    if (!sectionName) {
      alert('차시 제목을 입력해주세요.');
      return;
    }
    const validVideos = (session.videos || []).filter((v) => (v.url || '').trim() !== '');
    if (validVideos.length === 0) {
      alert('최소 1개 이상의 레슨(또는 URL)을 추가해주세요.');
      return;
    }

    try {
      const sectionRes = await tutorLmsApi.insertCurriculumSection({ courseId, sectionName });
      if (sectionRes.rst_code !== '0000') throw new Error(sectionRes.rst_message);

      const sectionId = Number(sectionRes.rst_data);
      if (!sectionId) throw new Error('차시 생성 결과가 올바르지 않습니다.');

      const errors: string[] = [];
      for (const video of validVideos) {
        const value = (video.url || '').trim();
        try {
          if (isNumericId(value)) {
            const addRes = await tutorLmsApi.addCurriculumLesson({
              courseId,
              sectionId,
              lessonId: Number(value),
            });
            if (addRes.rst_code !== '0000') errors.push(addRes.rst_message);
          } else {
            const addRes = await tutorLmsApi.addCurriculumLesson({
              courseId,
              sectionId,
              url: value,
              title: (video.title || '').trim() || sectionName,
            });
            if (addRes.rst_code !== '0000') errors.push(addRes.rst_message);
          }
        } catch (e) {
          errors.push(e instanceof Error ? e.message : '레슨 추가 중 오류가 발생했습니다.');
        }
      }

      if (errors.length > 0) {
        alert(`차시는 생성되었지만, 일부 레슨 추가에 실패했습니다.\n- ${errors.join('\n- ')}`);
      } else {
        alert('차시가 추가되었습니다.');
      }

      await refresh();
      setExpandedSectionId(sectionId);
    } catch (e) {
      alert(e instanceof Error ? e.message : '차시 추가 중 오류가 발생했습니다.');
    }
  };

  const handleRenameSection = async (sectionId: number, currentName: string) => {
    const nextName = window.prompt('새 차시 제목을 입력해주세요.', currentName);
    if (nextName === null) return;
    const sectionName = nextName.trim();
    if (!sectionName) return;

    try {
      const res = await tutorLmsApi.modifyCurriculumSection({ courseId, sectionId, sectionName });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);
      await refresh();
    } catch (e) {
      alert(e instanceof Error ? e.message : '차시 제목 수정 중 오류가 발생했습니다.');
    }
  };

  const handleDeleteSection = async (sectionId: number, sectionName: string) => {
    // 왜: 섹션 삭제 API는 연결된 레슨을 "기본"으로 이동시키므로, 사용자가 놀라지 않게 안내합니다.
    const ok = window.confirm(`차시 "${sectionName}"를 삭제하시겠습니까?\n(연결된 레슨은 '기본' 차시로 이동합니다.)`);
    if (!ok) return;

    try {
      const res = await tutorLmsApi.deleteCurriculumSection({ courseId, sectionId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);
      await refresh();
      if (expandedSectionId === sectionId) setExpandedSectionId(null);
    } catch (e) {
      alert(e instanceof Error ? e.message : '차시 삭제 중 오류가 발생했습니다.');
    }
  };

  const handleAddLessonToSection = async (sectionId: number) => {
    const raw = window.prompt('추가할 레슨ID(숫자) 또는 외부 URL을 입력해주세요.');
    if (raw === null) return;
    const value = raw.trim();
    if (!value) return;

    try {
      if (isNumericId(value)) {
        const res = await tutorLmsApi.addCurriculumLesson({ courseId, sectionId, lessonId: Number(value) });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);
      } else {
        const title = (window.prompt('외부 URL 레슨 제목(선택)', '') || '').trim();
        const res = await tutorLmsApi.addCurriculumLesson({ courseId, sectionId, url: value, title });
        if (res.rst_code !== '0000') throw new Error(res.rst_message);
      }
      await refresh();
      setExpandedSectionId(sectionId);
    } catch (e) {
      alert(e instanceof Error ? e.message : '레슨 추가 중 오류가 발생했습니다.');
    }
  };

  const handleDeleteLesson = async (lessonId: number) => {
    const ok = window.confirm('이 레슨을 강의목차에서 제거하시겠습니까?');
    if (!ok) return;

    try {
      const res = await tutorLmsApi.deleteCurriculumLesson({ courseId, lessonId });
      if (res.rst_code !== '0000') throw new Error(res.rst_message);
      await refresh();
    } catch (e) {
      alert(e instanceof Error ? e.message : '레슨 제거 중 오류가 발생했습니다.');
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center mb-4">
        <div className="text-sm text-gray-600">
          차시 {sessions.length}개 · 레슨 {rows.length}개
        </div>
        <button
          onClick={() => setCreateModalOpen(true)}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Plus className="w-4 h-4" />
          <span>차시 추가</span>
        </button>
      </div>

      {loading && (
        <div className="text-sm text-gray-600">불러오는 중...</div>
      )}
      {errorMessage && (
        <div className="text-sm text-red-600">{errorMessage}</div>
      )}

      {!loading && !errorMessage && sessions.length === 0 && (
        <div className="text-sm text-gray-600">등록된 강의목차가 없습니다.</div>
      )}

      {sessions.map((session) => {
        const isExpanded = expandedSectionId === session.sectionId;
        const isDefault = session.sectionId === 0;
        const Icon = isExpanded ? ChevronDown : ChevronRight;

        return (
          <div key={session.sectionId} className="border border-gray-200 rounded-lg overflow-hidden">
            <button
              onClick={() => toggleSection(session.sectionId)}
              className="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-center gap-3">
                <Icon className="w-5 h-5 text-gray-400" />
                <div className="text-left">
                  <div className="text-gray-900">{session.sectionName}</div>
                  <div className="text-sm text-gray-600">레슨 {session.lessons.length}개</div>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    handleAddLessonToSection(session.sectionId);
                  }}
                  className="flex items-center gap-1 px-3 py-1.5 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  <Plus className="w-4 h-4" />
                  <span>레슨 추가</span>
                </button>

                <button
                  type="button"
                  disabled={isDefault}
                  onClick={(e) => {
                    e.stopPropagation();
                    if (isDefault) return;
                    handleRenameSection(session.sectionId, session.sectionName);
                  }}
                  className={`p-2 rounded-lg transition-colors ${
                    isDefault ? 'text-gray-300 cursor-not-allowed' : 'text-gray-400 hover:text-gray-600 hover:bg-gray-100'
                  }`}
                  title={isDefault ? '기본 차시는 이름을 바꿀 수 없습니다.' : '차시 제목 수정'}
                >
                  <Edit className="w-4 h-4" />
                </button>

                <button
                  type="button"
                  disabled={isDefault}
                  onClick={(e) => {
                    e.stopPropagation();
                    if (isDefault) return;
                    handleDeleteSection(session.sectionId, session.sectionName);
                  }}
                  className={`p-2 rounded-lg transition-colors ${
                    isDefault ? 'text-gray-300 cursor-not-allowed' : 'text-gray-400 hover:text-red-600 hover:bg-red-50'
                  }`}
                  title={isDefault ? '기본 차시는 삭제할 수 없습니다.' : '차시 삭제'}
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </button>

            {isExpanded && (
              <div className="border-t border-gray-200 bg-gray-50 p-4 space-y-2">
                {session.lessons.length === 0 ? (
                  <div className="text-sm text-gray-500">레슨이 없습니다.</div>
                ) : (
                  session.lessons.map((lesson) => (
                    <div
                      key={lesson.lessonId}
                      className="flex items-center justify-between bg-white border border-gray-200 rounded-lg p-3"
                    >
                      <div className="min-w-0">
                        <div className="text-sm text-gray-900 truncate">
                          {lesson.chapter}. {lesson.lessonName}
                        </div>
                        <div className="text-xs text-gray-600">길이: {lesson.duration}</div>
                      </div>

                      <button
                        type="button"
                        onClick={() => handleDeleteLesson(lesson.lessonId)}
                        className="p-2 text-gray-400 hover:text-red-600 transition-colors"
                        title="레슨 제거"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  ))
                )}
              </div>
            )}
          </div>
        );
      })}

      <SessionEditModal
        isOpen={createModalOpen}
        onClose={() => setCreateModalOpen(false)}
        session={{ id: sessions.length + 1, title: '', description: '', videos: [] }}
        onSave={(updated) => {
          handleCreateSession(updated);
        }}
      />
    </div>
  );
}
