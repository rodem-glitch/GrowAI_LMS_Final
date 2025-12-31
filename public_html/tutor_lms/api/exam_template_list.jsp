<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

// 왜 필요한가:
// - 교수자 LMS > 시험관리에서 시험 템플릿 목록을 조회하기 위함입니다.

ExamDao exam = new ExamDao();

int limit = m.ri("limit") > 0 ? m.ri("limit") : 50;
int pageNum = m.ri("page") > 0 ? m.ri("page") : 1;

// 목록 조회 (ListManager 사용)
ListManager lm = new ListManager();
lm.setRequest(request);
lm.setListNum(limit);
lm.setTable(exam.table);
lm.setFields("*");
lm.addWhere("site_id = " + siteId);
lm.addWhere("status != -1");

// 교수자는 본인 시험만 조회
if(!isAdmin) {
	lm.addWhere("manager_id = " + userId);
}

lm.setOrderBy("id DESC");

// 포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), exam.onoffTypes));
	list.put("status_conv", m.getItem(list.s("status"), exam.statusList));
	
	// 총점 계산 (난이도별 배점 * 문항수)
	int totalPoints = 0;
	for(int i = 1; i <= 6; i++) {
		int mcnt = list.i("mcnt" + i);
		int tcnt = list.i("tcnt" + i);
		int assign = list.i("assign" + i);
		totalPoints += (mcnt + tcnt) * assign;
	}
	list.put("total_points", totalPoints);
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_total", lm.getTotalNum());
result.put("rst_page", pageNum);
result.put("rst_limit", limit);
result.put("rst_data", list);
result.print();

%>
