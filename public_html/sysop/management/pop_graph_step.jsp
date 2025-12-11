<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//유효성검사
if(courseId == 0) { m.jsErrClose("기본키는 반드시 있어야 합니다."); return; }

//객체
CourseUserDao cu = new CourseUserDao();

DataSet info = course.find("id = " + courseId);
if(!info.next()) { m.jsErrClose("해당 정보를 찾을 수 없습니다."); return; }

info.put("start_date_conv", m.time("yyyy.MM.dd", info.s("study_sdate")));
info.put("end_date_conv", "20991231".equals(info.s("study_edate")) ? "상시" : m.time("yyyy.MM.dd", info.s("study_edate")));

//점수별 분류
DataSet items = cu.query(
	"SELECT COUNT(*) u_cnt"
	+ ", SUM(CASE WHEN cu.close_yn = 'Y' AND cu.complete_yn = 'Y' THEN 1 ELSE 0 END) c_cnt"
	+ ", SUM(CASE WHEN cu.total_score >= 90.0 THEN 1 ELSE 0 END) p90_cnt"
	+ ", SUM(CASE WHEN cu.total_score < 90.0 AND cu.total_score >= 80.0 THEN 1 ELSE 0 END) p80_cnt"
	+ ", SUM(CASE WHEN cu.total_score < 80.0 AND cu.total_score >= 70.0 THEN 1 ELSE 0 END) p70_cnt"
	+ ", SUM(CASE WHEN cu.total_score < 70.0 AND cu.total_score >= 60.0 THEN 1 ELSE 0 END) p60_cnt"
	+ ", SUM(CASE WHEN cu.total_score < 60.0 THEN 1 ELSE 0 END) else_cnt"
	+ " FROM " + cu.table + " cu "
	+ " WHERE cu.course_id = " + courseId + " AND cu.status IN (1,3) "
);

if(!items.next()) { items.addRow(); }

if(items.i("u_cnt") == 0) {
	items.put("p90_cnt", 0); items.put("p90_rate", 0.0);
	items.put("p80_cnt", 0); items.put("p80_rate", 0.0);
	items.put("p70_cnt", 0); items.put("p70_rate", 0.0);
	items.put("p60_cnt", 0); items.put("p60_rate", 0.0);
	items.put("else_cnt", 0); items.put("else_rate", 0.0); items.put("else_rate2", 100.0); items.put("t_rate", 0.0);
} else {
	items.put("p90_rate", m.nf(Math.round(items.d("p90_cnt") * 100 / items.i("u_cnt")), 1));
	items.put("p80_rate", m.nf(Math.round(items.d("p80_cnt") * 100 / items.i("u_cnt")), 1));
	items.put("p70_rate", m.nf(Math.round(items.d("p70_cnt") * 100 / items.i("u_cnt")), 1));
	items.put("p60_rate", m.nf(Math.round(items.d("p60_cnt") * 100 / items.i("u_cnt")), 1));
	items.put("else_rate", m.nf(Math.round(items.d("else_cnt") * 100 / items.i("u_cnt")), 1));
	items.put("else_rate2", items.s("else_rate"));  items.put("t_rate", 100.0);
}

info.put("complete_rate", m.nf(items.i("u_cnt") > 0 ? items.d("c_cnt") / items.i("u_cnt") * 100 : 0.0, 1));
items.put("u_cnt_conv", m.nf(items.i("u_cnt"))); items.put("c_cnt_conv", m.nf(items.i("c_cnt")));

for(int i=0, max=cu.scoreFields.length; i<max; i++) {
	info.put("assign_" + cu.scoreFields[i], info.i("assign_" + cu.scoreFields[i]));
	info.put("total_assign", info.i("total_assign") + info.i("assign_" + cu.scoreFields[i]));
	info.put("limit_" + cu.scoreFields[i], info.i("limit_" + cu.scoreFields[i]));
	info.put("total_limit", info.i("total_limit") + info.i("limit_" + cu.scoreFields[i]));
}

//페이지 출력
p.setLayout("pop");
p.setBody("management.pop_graph_step");
p.setVar("p_title", "성적분포");
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setVar("items", items);

p.display();

%>