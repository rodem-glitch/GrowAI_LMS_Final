// components/common/Footer.tsx — 푸터 (다국어 + 상세 팝업)
import { useState } from 'react';
import { useTranslation } from '@/i18n';
import { X, FileText, Shield, Headphones } from 'lucide-react';

type ModalType = 'terms' | 'privacy' | 'support' | null;

const modalContent: Record<string, { icon: React.ElementType; title: string; content: string }> = {
  terms: {
    icon: FileText,
    title: '이용약관',
    content: `제1조 (목적)
이 약관은 GrowAI LMS(이하 "서비스")가 제공하는 온라인 교육 서비스의 이용조건 및 절차, 이용자와 서비스 제공자의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (정의)
① "서비스"란 한국폴리텍대학교가 운영하는 GrowAI LMS 학습관리시스템을 말합니다.
② "이용자"란 본 약관에 따라 서비스를 이용하는 학생, 교수자, 관리자를 말합니다.
③ "콘텐츠"란 서비스 내에서 제공되는 강의, 과제, 시험 등 교육 관련 자료를 말합니다.

제3조 (약관의 효력)
① 본 약관은 서비스 화면에 게시하거나 기타 방법으로 이용자에게 공지함으로써 효력이 발생합니다.
② 서비스는 관련 법령에 위배되지 않는 범위에서 본 약관을 변경할 수 있습니다.

제4조 (서비스의 제공)
① 서비스는 연중무휴 24시간 제공함을 원칙으로 합니다.
② 시스템 점검, 업데이트 등의 사유로 서비스 제공이 일시 중단될 수 있습니다.

제5조 (이용자의 의무)
① 이용자는 타인의 계정을 도용하거나 부정 접속하여서는 안 됩니다.
② 이용자는 서비스 내 콘텐츠를 무단 복제, 배포하여서는 안 됩니다.
③ 시험 및 과제 수행 시 부정행위를 하여서는 안 됩니다.`
  },
  privacy: {
    icon: Shield,
    title: '개인정보처리방침',
    content: `1. 개인정보의 수집 및 이용 목적
GrowAI LMS는 다음의 목적으로 개인정보를 수집 및 이용합니다.
- 회원 가입 및 관리: 회원 식별, 본인 인증, 서비스 제공
- 교육 서비스 제공: 강의 수강, 성적 관리, 수료증 발급
- AI 서비스 제공: AI 학습 도우미, 맞춤형 추천, 자소서 생성
- 통계 분석: 서비스 개선을 위한 익명화된 데이터 분석

2. 수집하는 개인정보 항목
- 필수항목: 성명, 학번, 이메일, 소속학과, 캠퍼스 정보
- 선택항목: 휴대전화번호, 프로필 사진
- 자동수집: 접속 IP, 접속 시간, 학습 이력, 서비스 이용 기록

3. 개인정보의 보유 및 이용 기간
- 회원 탈퇴 시까지 (단, 관계 법령에 따라 보존이 필요한 경우 해당 기간까지)
- 수료 기록: 졸업 후 5년간 보관
- 접속 로그: 3개월간 보관 후 파기

4. 개인정보의 제3자 제공
- 원칙적으로 이용자의 개인정보를 제3자에게 제공하지 않습니다.
- 법령에 의한 경우, 이용자의 동의가 있는 경우에 한해 제공합니다.

5. 개인정보의 안전성 확보 조치
- 개인정보 암호화 저장 (AES-256)
- SSL/TLS 통신 암호화
- 접근 권한 관리 및 로그 기록
- 정기적 보안 점검 및 취약점 진단

6. 개인정보 보호 책임자
- 성명: 김보안 | 직위: 정보보안팀장
- 이메일: privacy@growai.co.kr`
  },
  support: {
    icon: Headphones,
    title: '고객센터',
    content: `📞 고객센터 안내

■ 운영 시간
- 평일: 09:00 ~ 18:00 (점심시간 12:00~13:00)
- 토/일/공휴일: 휴무

■ 연락처
- 대표전화: 1588-0000
- 이메일: support@growai.co.kr
- 카카오톡: @GrowAI_LMS

■ 자주 묻는 질문 (FAQ)

Q. 비밀번호를 분실했습니다.
A. 로그인 화면의 "비밀번호 찾기"를 클릭하여 등록된 이메일로 재설정할 수 있습니다.

Q. 수강신청은 어떻게 하나요?
A. "강좌 탐색" 메뉴에서 원하는 강좌를 선택하고 "수강신청" 버튼을 클릭하세요.

Q. 수료증은 어디서 발급받나요?
A. "마이페이지 > 수료증" 메뉴에서 다운로드 및 인쇄가 가능합니다.

Q. AI 도우미가 응답하지 않습니다.
A. 일시적인 서버 부하일 수 있습니다. 잠시 후 다시 시도해주세요. 지속될 경우 고객센터로 문의해주세요.

Q. 개인정보 수정은 어떻게 하나요?
A. "마이페이지 > 프로필" 메뉴에서 직접 수정하거나, 학적 정보의 경우 KPOLY 학사시스템과 동기화됩니다.`
  }
};

export default function Footer() {
  const { t } = useTranslation();
  const [modal, setModal] = useState<ModalType>(null);

  const openModal = (type: ModalType, e: React.MouseEvent) => {
    e.preventDefault();
    setModal(type);
  };

  return (
    <>
      <footer className="border-t border-gray-100 dark:border-slate-800 py-6 mt-auto">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 flex flex-col sm:flex-row items-center justify-between gap-2">
          <p className="text-xs text-gray-400">{t('common.footerCopyright')}</p>
          <div className="flex items-center gap-4 text-xs text-gray-400">
            <a href="#" onClick={e => openModal('terms', e)} className="hover:text-gray-600 dark:hover:text-slate-300 transition-colors">{t('common.terms')}</a>
            <a href="#" onClick={e => openModal('privacy', e)} className="hover:text-gray-600 dark:hover:text-slate-300 font-semibold transition-colors">{t('common.privacy')}</a>
            <a href="#" onClick={e => openModal('support', e)} className="hover:text-gray-600 dark:hover:text-slate-300 transition-colors">{t('common.support')}</a>
          </div>
        </div>
      </footer>

      {modal && modalContent[modal] && (
        <div className="fixed inset-0 z-[100] flex items-start justify-center pt-16 bg-black/40 backdrop-blur-sm"
          onClick={() => setModal(null)}>
          <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl w-full max-w-xl mx-4 max-h-[80vh] flex flex-col animate-in slide-in-from-top-4 fade-in duration-300"
            onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 dark:border-gray-700 shrink-0">
              <h2 className="text-base font-bold text-gray-900 dark:text-white flex items-center gap-2">
                {(() => { const Icon = modalContent[modal].icon; return <Icon className="w-5 h-5 text-primary-500" />; })()}
                {modalContent[modal].title}
              </h2>
              <button onClick={() => setModal(null)} className="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors">
                <X className="w-4 h-4 text-gray-400" />
              </button>
            </div>
            <div className="overflow-y-auto flex-1 px-6 py-5">
              <pre className="text-sm text-gray-700 dark:text-slate-300 whitespace-pre-wrap leading-relaxed font-sans">
                {modalContent[modal].content}
              </pre>
            </div>
            <div className="px-6 py-3 border-t border-gray-100 dark:border-gray-700 shrink-0 text-center">
              <button onClick={() => setModal(null)} className="btn-primary text-sm px-6">닫기</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
