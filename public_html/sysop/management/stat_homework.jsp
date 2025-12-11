<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//기본키
int hid = m.ri("hid");
if(courseId == 0 || hid == 0) { m.jsErrClose("기본키는 반드시 있어야 합니다."); return; }

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
HomeworkDao homework = new HomeworkDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

//정보
DataSet info = courseModule.query(
	"SELECT a.course_id, a.apply_type, a.start_date, a.end_date, a.chapter, a.assign_score "
	+ ", h.* "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + homework.table + " h ON a.module_id = h.id "
	+ " WHERE a.status = 1 AND a.module = 'homework' "
	+ " AND a.course_id = " + courseId + " AND a.module_id = " + hid + ""
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("onoff_type_conv", m.getItem(info.s("onoff_type"), homework.onoffTypes));
info.put("online_block", "N".equals(info.s("onoff_type")));
if("1".equals(info.s("apply_type"))) { //기간
	info.put("start_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("start_date")));
	info.put("end_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("end_date")));

	info.put("apply_type_1", true);
	info.put("apply_type_2", false);
} else if("2".equals(info.s("apply_type"))) { //차시
	info.put("apply_conv", info.i("chapter") == 0 ? "학습시작 전" : info.i("chapter") + " 차시 학습 후");

	info.put("apply_type_1", false);
	info.put("apply_type_2", true);
}

//현황
DataSet stat = courseModule.query(
	"SELECT COUNT(*) u_cnt "
	+ ", SUM( CASE WHEN e.submit_yn = 'Y' THEN 1 ELSE 0 END ) s_cnt "
	+ ", SUM( CASE WHEN e.submit_yn = 'Y' AND e.confirm_yn = 'Y' THEN 1 ELSE 0 END ) c_cnt "
	+ ", SUM( CASE WHEN e.submit_yn = 'Y' AND e.confirm_yn = 'Y' THEN e.marking_score ELSE 0 END ) t_score "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " LEFT JOIN " + homeworkUser.table + " e "
		+ " ON e.homework_id = " + hid + " AND e.course_user_id = a.id AND e.status = 1 "
	+ " WHERE a.status IN (1,3) AND a.course_id = " + courseId + " "
);
if(!stat.next()) stat.addRow();
stat.put("join_rate", m.nf(stat.i("u_cnt") > 0 ? stat.d("s_cnt") / stat.i("u_cnt") * 100 : 0.0, 1));
stat.put("eva_rate", m.nf(stat.i("s_cnt") > 0 ? stat.d("c_cnt") / stat.i("s_cnt") * 100 : 0.0, 1));
stat.put("u_cnt_conv", m.nf(stat.i("u_cnt")));
stat.put("s_cnt_conv", m.nf(stat.i("s_cnt")));
stat.put("c_cnt_conv", m.nf(stat.i("c_cnt")));
stat.put("avg_score", m.nf(stat.i("c_cnt") > 0 ? stat.d("t_score") / stat.i("c_cnt") : 0.0, 1));

//점수
DataSet items = courseModule.query(
	"SELECT COUNT(*) t_cnt "
	+ ", SUM(CASE WHEN eu.marking_score >= 90.0 THEN 1 ELSE 0 END) p90_cnt "
	+ ", SUM(CASE WHEN eu.marking_score < 90.0 AND eu.marking_score >= 80.0 THEN 1 ELSE 0 END) p80_cnt "
	+ ", SUM(CASE WHEN eu.marking_score < 80.0 AND eu.marking_score >= 70.0 THEN 1 ELSE 0 END) p70_cnt "
	+ ", SUM(CASE WHEN eu.marking_score < 70.0 AND eu.marking_score >= 60.0 THEN 1 ELSE 0 END) p60_cnt "
	+ ", SUM(CASE WHEN eu.marking_score < 60.0 THEN 1 ELSE 0 END) else_cnt "
	+ " FROM " + homeworkUser.table + " eu "
	+ " INNER JOIN " + courseUser.table + " cu ON eu.course_user_id = cu.id AND cu.status IN (1,3) "
	+ " INNER JOIN " + user.table + " u ON u.id = cu.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE eu.homework_id = " + hid + " AND eu.course_id = " + courseId + " "
	+ " AND eu.status = 1 AND eu.submit_yn = 'Y' AND eu.confirm_yn = 'Y'"

);
if(!items.next()) items.addRow();
if(items.i("t_cnt") == 0) {
	items.put("p90_cnt", 0); items.put("p90_rate", 0.0);
	items.put("p80_cnt", 0); items.put("p80_rate", 0.0);
	items.put("p70_cnt", 0); items.put("p70_rate", 0.0);
	items.put("p60_cnt", 0); items.put("p60_rate", 0.0);
	items.put("else_cnt", 0); items.put("else_rate", 0.0); items.put("else_rate2", 100.0); items.put("t_rate", 0.0);
} else {
	items.put("p90_rate", m.nf(Math.round(items.d("p90_cnt") * 100 / items.i("t_cnt")), 1));
	items.put("p80_rate", m.nf(Math.round(items.d("p80_cnt") * 100 / items.i("t_cnt")), 1));
	items.put("p70_rate", m.nf(Math.round(items.d("p70_cnt") * 100 / items.i("t_cnt")), 1));
	items.put("p60_rate", m.nf(Math.round(items.d("p60_cnt") * 100 / items.i("t_cnt")), 1));
	items.put("else_rate", m.nf(Math.round(items.d("else_cnt") * 100 / items.i("t_cnt")), 1));
	items.put("else_rate2", items.s("else_rate"));  items.put("t_rate", 100.0);
}

//출력
p.setLayout("pop");
p.setBody("management.stat_homework");
p.setVar("p_title", "과제 성적분포");
p.setVar("form_script", f.getScript());

p.setVar("homework", info);
p.setVar("stat", stat);
p.setVar("items", items);
p.display();

%>