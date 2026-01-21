import { useEffect, useRef, useState } from 'react';

// 왜: 기존 통계 대시보드(polytech-lms-api의 정적 HTML)를 교수자 LMS 안에서 바로 보이게 해야 합니다.
//     단, 화면 내부에서 `/statistics/api/*`를 호출하므로, 같은 도메인에서 프록시를 거치도록 URL을 고정합니다.
const STATISTICS_DASHBOARD_URL = '/tutor_lms/api/statistics_proxy.jsp/statistics/dashboard.html';

// 왜: 통계 대시보드를 전체 페이지 스크롤로 표시하기 위해 iframe 높이를 콘텐츠에 맞춰 동적으로 조정합니다.
//     고정 높이 컨테이너를 사용하면 이중 스크롤이 발생하므로, 콘텐츠 크기에 맞춰 확장합니다.
export function StatisticsPage() {
  const iframeRef = useRef<HTMLIFrameElement>(null);
  const [iframeHeight, setIframeHeight] = useState(800); // 초기 높이

  useEffect(() => {
    const iframe = iframeRef.current;
    if (!iframe) return;

    const adjustHeight = () => {
      try {
        const doc = iframe.contentDocument || iframe.contentWindow?.document;
        if (doc && doc.body) {
          // 왜: scrollHeight로 전체 콘텐츠 높이를 측정하고, 여유 공간(padding)을 추가합니다.
          const contentHeight = doc.documentElement.scrollHeight || doc.body.scrollHeight;
          setIframeHeight(contentHeight + 40);
        }
      } catch (e) {
        // 왜: cross-origin 제한이 있을 경우 기본 높이를 충분히 크게 설정합니다.
        setIframeHeight(1600);
      }
    };

    iframe.addEventListener('load', adjustHeight);
    // 왜: 탭 전환 등으로 콘텐츠가 변경될 때도 높이를 재조정합니다.
    const resizeTimer = setInterval(adjustHeight, 500);

    return () => {
      iframe.removeEventListener('load', adjustHeight);
      clearInterval(resizeTimer);
    };
  }, []);

  return (
    <div className="bg-white rounded-lg shadow-sm overflow-visible">
      <iframe
        ref={iframeRef}
        src={STATISTICS_DASHBOARD_URL}
        title="통계 대시보드"
        className="w-full border-0"
        style={{ height: `${iframeHeight}px`, minHeight: '600px' }}
      />
    </div>
  );
}
