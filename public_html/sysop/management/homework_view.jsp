<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

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
	+ " AND a.course_id = " + courseId + " AND a.module_id = " + id + ""
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
if("1".equals(info.s("apply_type"))) { //기간
	info.put("start_date_conv", m.time("yyyy.MM.dd HH시 mm분", info.s("start_date")));
	info.put("end_date_conv", m.time("yyyy.MM.dd HH시 mm분", info.s("end_date")));

	info.put("apply_type_1", true);
	info.put("apply_type_2", false);
} else if("2".equals(info.s("apply_type"))) { //차시
	info.put("apply_conv", info.i("chapter") == 0 ? "학습시작 전" : info.i("chapter") + " 차시 학습 후");

	info.put("apply_type_1", false);
	info.put("apply_type_2", true);
}
info.put("onoff_type_conv", m.getItem(info.s("onoff_type"), homework.onoffTypes));
info.put("homework_file_conv", m.encode(info.s("homework_file")));
info.put("homework_file_url", siteDomain + m.getUploadUrl(info.s("homework_file")));
info.put("homework_file_ek", m.encrypt(info.s("homework_file") + m.time("yyyyMMdd")));

//현황
DataSet stat = courseModule.query(
	"SELECT COUNT(*) u_cnt "
	+ ", SUM( CASE WHEN h.submit_yn = 'Y' THEN 1 ELSE 0 END ) s_cnt "
	+ ", SUM( CASE WHEN h.submit_yn = 'Y' AND h.confirm_yn = 'Y' THEN 1 ELSE 0 END ) c_cnt "
	+ ", SUM( CASE WHEN h.submit_yn = 'Y' AND h.confirm_yn = 'Y' THEN h.marking_score ELSE 0 END ) t_score "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " LEFT JOIN " + homeworkUser.table + " h "
		+ " ON h.homework_id = " + id + " AND h.course_user_id = a.id AND h.status = 1 "
	+ " WHERE a.status IN (1,3) AND a.course_id = " + courseId + " "
);
if(!stat.next()) stat.addRow();
stat.put("join_rate", m.nf(stat.i("u_cnt") > 0 ? stat.d("s_cnt") / stat.i("u_cnt") * 100 : 0.0, 1));
stat.put("eva_rate", m.nf(stat.i("s_cnt") > 0 ? stat.d("c_cnt") / stat.i("s_cnt") * 100 : 0.0, 1));
stat.put("u_cnt_conv", m.nf(stat.i("u_cnt")));
stat.put("s_cnt_conv", m.nf(stat.i("s_cnt")));
stat.put("c_cnt_conv", m.nf(stat.i("c_cnt")));
stat.put("avg_score", m.nf(stat.i("c_cnt") > 0 ? stat.d("t_score") / stat.i("c_cnt") : 0.0, 1));


//출력
p.setBody("management.homework_view");
p.setVar("p_title", ptitle);
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("homework", info);
p.setVar("stat", stat);
p.display();

%>