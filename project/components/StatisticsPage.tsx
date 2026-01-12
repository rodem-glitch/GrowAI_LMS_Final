// 왜: 기존 통계 대시보드(polytech-lms-api의 정적 HTML)를 교수자 LMS 안에서 바로 보이게 해야 합니다.
//     단, 화면 내부에서 `/statistics/api/*`를 호출하므로, 같은 도메인에서 프록시를 거치도록 URL을 고정합니다.
const STATISTICS_DASHBOARD_URL = '/tutor_lms/api/statistics_proxy.jsp/statistics/dashboard.html';

export function StatisticsPage() {
  return (
    <div className="bg-white rounded-lg shadow-sm overflow-hidden" style={{ height: 'calc(100vh - 140px)' }}>
      <iframe src={STATISTICS_DASHBOARD_URL} title="통계 대시보드" className="w-full h-full border-0" />
    </div>
  );
}
