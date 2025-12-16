import { useState } from 'react';
import { Edit } from 'lucide-react';

// 과목정보 메인 탭
export function CourseInfoTab({ course }: { course: any }) {
  const [subTab, setSubTab] = useState<'basic' | 'evaluation' | 'completion' | 'certificate'>('basic');
  const [useCertificate, setUseCertificate] = useState(false);

  return (
    <div className="space-y-6">
      {/* 하위 탭 네비게이션 */}
      <div className="flex gap-2 border-b border-gray-200">
        <button
          onClick={() => setSubTab('basic')}
          className={`px-4 py-2 transition-colors ${
            subTab === 'basic'
              ? 'border-b-2 border-blue-600 text-blue-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          기본 정보
        </button>
        <button
          onClick={() => setSubTab('evaluation')}
          className={`px-4 py-2 transition-colors ${
            subTab === 'evaluation'
              ? 'border-b-2 border-blue-600 text-blue-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          평가항목
        </button>
        <button
          onClick={() => setSubTab('completion')}
          className={`px-4 py-2 transition-colors ${
            subTab === 'completion'
              ? 'border-b-2 border-blue-600 text-blue-600'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          수료증
        </button>
        {useCertificate && (
          <button
            onClick={() => setSubTab('certificate')}
            className={`px-4 py-2 transition-colors ${
              subTab === 'certificate'
                ? 'border-b-2 border-blue-600 text-blue-600'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            합격증
          </button>
        )}
      </div>

      {/* 하위 탭 콘텐츠 */}
      {subTab === 'basic' && <BasicInfoTab course={course} />}
      {subTab === 'evaluation' && (
        <EvaluationTab useCertificate={useCertificate} setUseCertificate={setUseCertificate} />
      )}
      {subTab === 'completion' && <CompletionCertificateTab />}
      {subTab === 'certificate' && useCertificate && <PassCertificateTab />}
    </div>
  );
}

// 기본 정보 탭
function BasicInfoTab({ course }: { course: any }) {
  return (
    <div className="space-y-6">
      <div className="flex justify-end">
        <button
          onClick={() => alert('과목 정보 수정 기능')}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Edit className="w-4 h-4" />
          <span>수정</span>
        </button>
      </div>
      <div className="grid grid-cols-2 gap-6">
        <div>
          <label className="block text-sm text-gray-700 mb-2">과목명</label>
          <div className="px-4 py-3 bg-gray-50 rounded-lg text-gray-900">
            {course.subjectName}
          </div>
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-2">과정ID</label>
          <div className="px-4 py-3 bg-gray-50 rounded-lg text-gray-900">
            {course.courseId}
          </div>
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-2">과정구분</label>
          <div className="px-4 py-3 bg-gray-50 rounded-lg text-gray-900">
            {course.courseType}
          </div>
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-2">소속 과정명</label>
          <div className="px-4 py-3 bg-gray-50 rounded-lg text-gray-900">
            {course.programName}
          </div>
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-2">교육기간</label>
          <div className="px-4 py-3 bg-gray-50 rounded-lg text-gray-900">
            {course.period}
          </div>
        </div>
        <div>
          <label className="block text-sm text-gray-700 mb-2">수강인원</label>
          <div className="px-4 py-3 bg-gray-50 rounded-lg text-gray-900">
            {course.students}명
          </div>
        </div>
      </div>
      <div>
        <label className="block text-sm text-gray-700 mb-2">과목 개요</label>
        <div className="px-4 py-3 bg-gray-50 rounded-lg text-gray-900">
          본 과목은 웹 개발의 기초를 다루며, HTML, CSS, JavaScript의 기본 개념과 실습을
          통해 웹 페이지 제작 능력을 배양합니다.
        </div>
      </div>
      <div>
        <label className="block text-sm text-gray-700 mb-2">학습 목표</label>
        <div className="px-4 py-3 bg-gray-50 rounded-lg text-gray-900">
          • 웹 표준 HTML5와 CSS3를 활용한 웹 페이지 구조 설계 및 구현
          <br />
          • JavaScript 기본 문법과 DOM 조작을 통한 동적 웹 페이지 개발
          <br />• 반응형 웹 디자인의 이해와 실무 적용
        </div>
      </div>
    </div>
  );
}

// 평가항목 탭
function EvaluationTab({ useCertificate, setUseCertificate }: { useCertificate: boolean; setUseCertificate: (value: boolean) => void }) {
  const [scores, setScores] = useState({
    attendance: { total: 100, progress: 100 },
    exam: { total: 0 },
    material: { total: 0 },
    discussion: { total: 0 },
    other: { total: 0 },
  });

  const [criteria, setCriteria] = useState({
    totalScore: 60,
    progressRate: 60,
  });

  const [passCriteria, setPassCriteria] = useState({
    totalScore: 80,
    progressRate: 80,
  });

  const [settings, setSettings] = useState({
    surveyRequired: false,
    looseCriteria: false,
    surveyEnabled: false,
  });

  return (
    <div className="space-y-6">
      {/* 배점 비율 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <h4 className="text-gray-900 mb-4">배점 비율</h4>
        <div className="text-sm text-gray-600 mb-4">
          ▸ 총점 100점 만점 기준으로 각 평가항목의 점수를 입력하세요.
        </div>
        <div className="grid grid-cols-6 gap-4">
          <div className="text-center">
            <div className="bg-blue-100 text-blue-900 py-2 rounded-t-lg">출석</div>
            <div className="border border-t-0 border-gray-200 rounded-b-lg p-3">
              <div className="text-sm text-gray-700 mb-2">100점</div>
              <div className="space-y-2">
                <div>
                  <label className="text-xs text-gray-600">진도(출석)</label>
                  <div className="flex items-center gap-1 mt-1">
                    <input
                      type="number"
                      value={scores.attendance.progress}
                      onChange={(e) =>
                        setScores({
                          ...scores,
                          attendance: { ...scores.attendance, progress: parseInt(e.target.value) || 0 },
                        })
                      }
                      className="w-full px-2 py-1 border border-gray-300 rounded text-center"
                    />
                    <span className="text-xs text-gray-600">점(%)</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          {['exam', 'material', 'discussion', 'other'].map((key, index) => {
            const labels = ['시험', '교재', '토론', '기타'];
            return (
              <div key={key} className="text-center">
                <div className="bg-gray-100 text-gray-900 py-2 rounded-t-lg">{labels[index]}</div>
                <div className="border border-t-0 border-gray-200 rounded-b-lg p-3">
                  <div className="flex items-center gap-1">
                    <input
                      type="number"
                      value={scores[key].total}
                      onChange={(e) =>
                        setScores({
                          ...scores,
                          [key]: { total: parseInt(e.target.value) || 0 },
                        })
                      }
                      className="w-full px-2 py-1 border border-gray-300 rounded text-center"
                    />
                    <span className="text-xs text-gray-600">점(%)</span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
        <div className="text-sm text-gray-600 mt-4">
          ▸ 각 항목의 수료기준 100점만족 기준으로 입력해주세요.
        </div>
      </div>

      {/* 수료기준 기준 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <h4 className="text-gray-900 mb-4">수료기준 기준</h4>
        <div className="grid grid-cols-2 gap-6">
          <div>
            <label className="block text-sm text-gray-700 mb-2">총점</label>
            <div className="flex items-center gap-2">
              <input
                type="number"
                value={criteria.totalScore}
                onChange={(e) => setCriteria({ ...criteria, totalScore: parseInt(e.target.value) || 0 })}
                className="w-24 px-3 py-2 border border-gray-300 rounded"
              />
              <span className="text-sm text-gray-700">점 이상 / 100점</span>
            </div>
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-2">진도(출석)율</label>
            <div className="flex items-center gap-2">
              <input
                type="number"
                value={criteria.progressRate}
                onChange={(e) => setCriteria({ ...criteria, progressRate: parseInt(e.target.value) || 0 })}
                className="w-24 px-3 py-2 border border-gray-300 rounded"
              />
              <span className="text-sm text-gray-700">% 이상 / 100%</span>
            </div>
          </div>
        </div>
      </div>

      {/* 합격기준 기준 */}
      {useCertificate && (
        <div className="border border-gray-200 rounded-lg p-6">
          <h4 className="text-gray-900 mb-4">합격기준 기준</h4>
          <div className="grid grid-cols-2 gap-6">
            <div>
              <label className="block text-sm text-gray-700 mb-2">총점</label>
              <div className="flex items-center gap-2">
                <input
                  type="number"
                  value={passCriteria.totalScore}
                  onChange={(e) => setPassCriteria({ ...passCriteria, totalScore: parseInt(e.target.value) || 0 })}
                  className="w-24 px-3 py-2 border border-gray-300 rounded"
                />
                <span className="text-sm text-gray-700">점 이상 / 100점</span>
              </div>
            </div>
            <div>
              <label className="block text-sm text-gray-700 mb-2">진도(출석)율</label>
              <div className="flex items-center gap-2">
                <input
                  type="number"
                  value={passCriteria.progressRate}
                  onChange={(e) => setPassCriteria({ ...passCriteria, progressRate: parseInt(e.target.value) || 0 })}
                  className="w-24 px-3 py-2 border border-gray-300 rounded"
                />
                <span className="text-sm text-gray-700">% 이상 / 100%</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 설문참여 확산 여부 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <h4 className="text-gray-900 mb-2">설문참여 확산 여부</h4>
            <p className="text-sm text-gray-600">
              ▸ 수료기준에 설문참여여부를 포함합니다. 모든 설문에 참여해야 수료기준에 충족됩니다.
            </p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer ml-4">
            <input
              type="checkbox"
              checked={settings.surveyRequired}
              onChange={(e) => setSettings({ ...settings, surveyRequired: e.target.checked })}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
      </div>

      {/* 수료기준 느슨 여부 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <h4 className="text-gray-900 mb-2">수료기준 느슨 여부</h4>
            <p className="text-sm text-gray-600">
              ▸ 사용자의 감정상태 변이가 심하면 수료기준을 느슨하게 합니다.
            </p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer ml-4">
            <input
              type="checkbox"
              checked={settings.looseCriteria}
              onChange={(e) => setSettings({ ...settings, looseCriteria: e.target.checked })}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
      </div>

      {/* 설문참여 확산 가능 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <h4 className="text-gray-900 mb-2">설문참여 확산 가능</h4>
            <p className="text-sm text-gray-600">
              ▸ 진도기준을 충족한 수강생에게 설문참여를 확산합니다.
            </p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer ml-4">
            <input
              type="checkbox"
              checked={settings.surveyEnabled}
              onChange={(e) => setSettings({ ...settings, surveyEnabled: e.target.checked })}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
      </div>

      {/* 합격증 사용 여부 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <h4 className="text-gray-900 mb-2">합격증 사용 여부</h4>
            <p className="text-sm text-gray-600">
              ▸ 합격증을 사용할지 여부를 설정합니다.
            </p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer ml-4">
            <input
              type="checkbox"
              checked={useCertificate}
              onChange={(e) => setUseCertificate(e.target.checked)}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
      </div>

      {/* 저장 버튼 */}
      <div className="flex justify-end">
        <button className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
          저장
        </button>
      </div>
    </div>
  );
}

// 수료증 탭
function CompletionCertificateTab() {
  const [certificateSettings, setCertificateSettings] = useState({
    template: '사용자지정중',
    useNumber: false,
    numberPrefix: '',
    firstDigit: 0,
    firstDigitType: 'enrollment', // enrollment or studentId
    duplicateHandling: 'error', // error or internal
  });

  return (
    <div className="space-y-6">
      {/* 수료증 정보 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <h4 className="text-gray-900 mb-4">수료증 정보</h4>
        <div>
          <label className="block text-sm text-gray-700 mb-2">수료증 템플릿</label>
          <select
            value={certificateSettings.template}
            onChange={(e) => setCertificateSettings({ ...certificateSettings, template: e.target.value })}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg"
          >
            <option value="사용자지정중">- 사용자지정중 -</option>
            <option value="템플릿1">템플릿 1</option>
            <option value="템플릿2">템플릿 2</option>
          </select>
          <p className="text-sm text-gray-600 mt-2">
            ▸ 수료증의 서식을 변경합니다. 설정하시면 사용자지정 기능 수료증 양식을 사용합니다.
          </p>
        </div>
      </div>

      {/* 수료번호 사용여부 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <div className="flex items-start justify-between mb-4">
          <div className="flex-1">
            <h4 className="text-gray-900 mb-2">수료번호 사용여부</h4>
            <p className="text-sm text-red-600">
              ▸ 학교에 설정된 수료번호 기준을 사용합니다. 지정하지 않으면 기본 수료번호 양식을 사용합니다.
            </p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer ml-4">
            <input
              type="checkbox"
              checked={certificateSettings.useNumber}
              onChange={(e) => setCertificateSettings({ ...certificateSettings, useNumber: e.target.checked })}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
      </div>

      {/* 수료번호 앞자리 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <h4 className="text-gray-900 mb-4">수료번호 앞자리</h4>
        <input
          type="text"
          value={certificateSettings.numberPrefix}
          onChange={(e) => setCertificateSettings({ ...certificateSettings, numberPrefix: e.target.value })}
          placeholder="수료번호 앞자리를 입력하세요"
          className="w-full px-3 py-2 border border-gray-300 rounded-lg"
        />
        <p className="text-sm text-gray-600 mt-2">
          ▸ 수료번호 앞자리를 입력합니다. 최대 20자까지 입력이 가능합니다.
        </p>
      </div>

      {/* 수료번호 첫자리수 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <h4 className="text-gray-900 mb-4">수료번호 첫자리수</h4>
        <input
          type="number"
          value={certificateSettings.firstDigit}
          onChange={(e) => setCertificateSettings({ ...certificateSettings, firstDigit: parseInt(e.target.value) || 0 })}
          className="w-32 px-3 py-2 border border-gray-300 rounded-lg"
        />
        <p className="text-sm text-gray-600 mt-2">
          ▸ 수료번호 첫자리수를 입력합니다. 최대 숫자까지 입력이 가능하며, 0을 입력하면 숫자가 그대로 유지됩니다.
        </p>
      </div>

      {/* 첫자리 번호방식 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <h4 className="text-gray-900 mb-4">첫자리 번호방식</h4>
        <div className="space-y-2">
          <label className="flex items-center gap-2">
            <input
              type="radio"
              name="firstDigitType"
              checked={certificateSettings.firstDigitType === 'enrollment'}
              onChange={() => setCertificateSettings({ ...certificateSettings, firstDigitType: 'enrollment' })}
              className="w-4 h-4 text-blue-600"
            />
            <span className="text-sm text-gray-900">수강연번</span>
          </label>
          <label className="flex items-center gap-2">
            <input
              type="radio"
              name="firstDigitType"
              checked={certificateSettings.firstDigitType === 'studentId'}
              onChange={() => setCertificateSettings({ ...certificateSettings, firstDigitType: 'studentId' })}
              className="w-4 h-4 text-blue-600"
            />
            <span className="text-sm text-gray-900">수강생번호</span>
          </label>
        </div>
        <p className="text-sm text-gray-600 mt-2">▸ 첫자리 번호방식을 선택합니다.</p>
      </div>

      {/* 첫자리 중복방식 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <h4 className="text-gray-900 mb-4">첫자리 중복방식</h4>
        <div className="space-y-2">
          <label className="flex items-center gap-2">
            <input
              type="radio"
              name="duplicateHandling"
              checked={certificateSettings.duplicateHandling === 'error'}
              onChange={() => setCertificateSettings({ ...certificateSettings, duplicateHandling: 'error' })}
              className="w-4 h-4 text-blue-600"
            />
            <span className="text-sm text-gray-900">오류차단</span>
          </label>
          <label className="flex items-center gap-2">
            <input
              type="radio"
              name="duplicateHandling"
              checked={certificateSettings.duplicateHandling === 'internal'}
              onChange={() => setCertificateSettings({ ...certificateSettings, duplicateHandling: 'internal' })}
              className="w-4 h-4 text-blue-600"
            />
            <span className="text-sm text-gray-900">내부차단</span>
          </label>
        </div>
        <p className="text-sm text-red-600 mt-2">
          ▸ 첫자리 번호방식을 수강생번호로 설정한 경우 중복발생시 선택합니다.
        </p>
      </div>

      {/* 저장 버튼 */}
      <div className="flex justify-end">
        <button className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
          저장
        </button>
      </div>
    </div>
  );
}

// 합격증 탭
function PassCertificateTab() {
  const [certificateSettings, setCertificateSettings] = useState({
    template: '사용자지정중',
    useNumber: false,
    numberPrefix: '',
    firstDigit: 0,
    firstDigitType: 'enrollment',
    duplicateHandling: 'error',
  });

  return (
    <div className="space-y-6">
      {/* 합격증 정보 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <h4 className="text-gray-900 mb-4">합격증 정보</h4>
        <div>
          <label className="block text-sm text-gray-700 mb-2">합격증 템플릿</label>
          <select
            value={certificateSettings.template}
            onChange={(e) => setCertificateSettings({ ...certificateSettings, template: e.target.value })}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg"
          >
            <option value="사용자지정중">- 사용자지정중 -</option>
            <option value="템플릿1">템플릿 1</option>
            <option value="템플릿2">템플릿 2</option>
          </select>
          <p className="text-sm text-gray-600 mt-2">
            ▸ 합격증의 서식을 변경합니다. 설정하시면 사용자지정 기능 합격증 양식을 사용합니다.
          </p>
        </div>
      </div>

      {/* 합격번호 사용여부 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <div className="flex items-start justify-between mb-4">
          <div className="flex-1">
            <h4 className="text-gray-900 mb-2">합격번호 사용여부</h4>
            <p className="text-sm text-red-600">
              ▸ 학교에 설정된 합격번호 기준을 사용합니다. 지정하지 않으면 기본 합격번호 양식을 사용합니다.
            </p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer ml-4">
            <input
              type="checkbox"
              checked={certificateSettings.useNumber}
              onChange={(e) => setCertificateSettings({ ...certificateSettings, useNumber: e.target.checked })}
              className="sr-only peer"
            />
            <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
          </label>
        </div>
      </div>

      {/* 합격번호 앞자리 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <h4 className="text-gray-900 mb-4">합격번호 앞자리</h4>
        <input
          type="text"
          value={certificateSettings.numberPrefix}
          onChange={(e) => setCertificateSettings({ ...certificateSettings, numberPrefix: e.target.value })}
          placeholder="합격번호 앞자리를 입력하세요"
          className="w-full px-3 py-2 border border-gray-300 rounded-lg"
        />
        <p className="text-sm text-gray-600 mt-2">
          ▸ 합격번호 앞자리를 입력합니다. 최대 20자까지 입력이 가능합니다.
        </p>
      </div>

      {/* 합격번호 첫자리수 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <h4 className="text-gray-900 mb-4">합격번호 첫자리수</h4>
        <input
          type="number"
          value={certificateSettings.firstDigit}
          onChange={(e) => setCertificateSettings({ ...certificateSettings, firstDigit: parseInt(e.target.value) || 0 })}
          className="w-32 px-3 py-2 border border-gray-300 rounded-lg"
        />
        <p className="text-sm text-gray-600 mt-2">
          ▸ 합격번호 첫자리수를 입력합니다. 최대 숫자까지 입력이 가능하며, 0을 입력하면 숫자가 그대로 유지됩니다.
        </p>
      </div>

      {/* 첫자리 번호방식 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <h4 className="text-gray-900 mb-4">첫자리 번호방식</h4>
        <div className="space-y-2">
          <label className="flex items-center gap-2">
            <input
              type="radio"
              name="firstDigitType-pass"
              checked={certificateSettings.firstDigitType === 'enrollment'}
              onChange={() => setCertificateSettings({ ...certificateSettings, firstDigitType: 'enrollment' })}
              className="w-4 h-4 text-blue-600"
            />
            <span className="text-sm text-gray-900">수강연번</span>
          </label>
          <label className="flex items-center gap-2">
            <input
              type="radio"
              name="firstDigitType-pass"
              checked={certificateSettings.firstDigitType === 'studentId'}
              onChange={() => setCertificateSettings({ ...certificateSettings, firstDigitType: 'studentId' })}
              className="w-4 h-4 text-blue-600"
            />
            <span className="text-sm text-gray-900">수강생번호</span>
          </label>
        </div>
        <p className="text-sm text-gray-600 mt-2">▸ 첫자리 번호방식을 선택합니다.</p>
      </div>

      {/* 첫자리 중복방식 */}
      <div className="border border-gray-200 rounded-lg p-6">
        <h4 className="text-gray-900 mb-4">첫자리 중복방식</h4>
        <div className="space-y-2">
          <label className="flex items-center gap-2">
            <input
              type="radio"
              name="duplicateHandling-pass"
              checked={certificateSettings.duplicateHandling === 'error'}
              onChange={() => setCertificateSettings({ ...certificateSettings, duplicateHandling: 'error' })}
              className="w-4 h-4 text-blue-600"
            />
            <span className="text-sm text-gray-900">오류차단</span>
          </label>
          <label className="flex items-center gap-2">
            <input
              type="radio"
              name="duplicateHandling-pass"
              checked={certificateSettings.duplicateHandling === 'internal'}
              onChange={() => setCertificateSettings({ ...certificateSettings, duplicateHandling: 'internal' })}
              className="w-4 h-4 text-blue-600"
            />
            <span className="text-sm text-gray-900">내부차단</span>
          </label>
        </div>
        <p className="text-sm text-red-600 mt-2">
          ▸ 첫자리 번호방식을 수강생번호로 설정한 경우 중복발생시 선택합니다.
        </p>
      </div>

      {/* 저장 버튼 */}
      <div className="flex justify-end">
        <button className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
          저장
        </button>
      </div>
    </div>
  );
}