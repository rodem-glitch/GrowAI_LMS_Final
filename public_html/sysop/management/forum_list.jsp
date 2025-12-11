<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();
ForumDao forum = new ForumDao();
ForumUserDao forumUser = new ForumUserDao();
MCal mcal = new MCal();

//변수
String applyType = "R".equals(cinfo.s("course_type")) ? "1" : "2";
int chapter = "R".equals(cinfo.s("course_type")) ? 1 : 0;

//처리
if("del".equals(m.rs("mode"))) {
	//기본키
	int id = m.ri("id");
	if(id == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	//정보
	DataSet info = forum.find("id = " + id + " AND status = 1 AND site_id = " + siteId + "");
	if(!info.next()) { m.jsAlert("해당 정보가 없습니다."); return; }

	//제한
	if(cinfo.i("assign_forum") > 0 && info.i("assign_score") > 0) {
		m.jsAlert("해당 토론이 삭제되면 배점비율과 각 시험의 배점합이 맞지 않게 됩니다. 배점을 0으로 수정한 다음 삭제해야 합니다."); return;
	}

	//제한
	if(0 < forumUser.findCount("forum_id = " + id + " AND course_id = " + courseId + "")) {
		m.jsAlert("제출내역이 있습니다. 삭제할 수 없습니다."); return;
	}

	//삭제
	if(!courseModule.delete("course_id = " + courseId + " AND module = 'forum' AND module_id = " + id + "")) {
		m.jsAlert("삭제하는 중 오류가 발생했습니다."); return;
	}

	m.jsAlert("삭제되었습니다.");
	m.jsReplace("forum_list.jsp?" + m.qs("id,mode"), "parent");
	return;
}

//수정
if("mod".equals(m.rs("mode")) && m.isPost()) {
	DataSet forums = f.getArrList(
		"id,apply_type"
		+ ",start_date,start_date_hour,start_date_min,end_date,end_date_hour,end_date_min"
		+ ",chapter,assign_score"
	);

	//제한
	if(forums.size() == 0) { m.jsAlert("수정할 토론이 없습니다."); return; }

	while(forums.next()) {
		courseModule.item("assign_score", forums.i("assign_score"));
		courseModule.item("apply_type", applyType);
		if("1".equals(applyType)) {
			String sdate = m.time("yyyyMMdd", forums.s("start_date")) + forums.s("start_date_hour") + forums.s("start_date_min") + "00";
			String edate = m.time("yyyyMMdd", forums.s("end_date")) + forums.s("end_date_hour") + forums.s("end_date_min") + "59";
			courseModule.item("start_date", sdate);
			courseModule.item("end_date", edate);
			courseModule.item("chapter", 0);
		} else if("2".equals(applyType)) {
			courseModule.item("start_date", "");
			courseModule.item("end_date", "");
			courseModule.item("chapter", forums.i("chapter"));
		}
		if(!courseModule.update("course_id = " + courseId + " AND module = 'forum' AND module_id = " + forums.i("id") + "")) {}
	}

	m.jsAlert("수정되었습니다.");
	m.jsReplace("forum_list.jsp?" + m.qs("id,mode"), "parent");
	return;
}

//목록
DataSet list = courseModule.query(
	"SELECT a.*, f.id, f.onoff_type, f.forum_nm "
	+ ", ( "
		+ " SELECT COUNT(*) FROM " + courseUser.table + " cu "
		+ " INNER JOIN " + user.table + " u ON u.id = cu.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
		+ " WHERE cu.course_id = a.course_id AND cu.status IN (1,3) "
	+ " ) u_cnt "
	+ ", ( "
		+ " SELECT COUNT(*) FROM " + forumUser.table + " u "
		+ " INNER JOIN " + courseUser.table + " c ON c.id = u.course_user_id AND c.status IN (1,3) "
		+ " INNER JOIN " + user.table + " v ON v.id = c.user_id " + (deptManagerBlock ? " AND v.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
		+ " WHERE u.forum_id = a.module_id AND u.course_id = a.course_id "
		+ " AND u.status = 1 AND u.submit_yn = 'Y' "
	+ " ) s_cnt "
	+ ", ( "
		+ " SELECT COUNT(*) FROM " + forumUser.table + " u "
		+ " INNER JOIN " + courseUser.table + " c ON c.id = u.course_user_id AND c.status IN (1,3) "
		+ " INNER JOIN " + user.table + " v ON v.id = c.user_id " + (deptManagerBlock ? " AND v.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
		+ " WHERE u.forum_id = a.module_id AND u.course_id = a.course_id "
		+ " AND u.status = 1 AND u.submit_yn = 'Y' AND u.confirm_yn = 'Y' "
	+ " ) c_cnt "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + forum.table + " f ON a.module_id = f.id AND f.status != -1 "
	+ " WHERE a.status = 1 AND a.module = 'forum' "
	+ " AND a.course_id = " + courseId + " AND f.site_id = " + siteId + " "
	+ " ORDER BY a.start_date ASC, a.end_date ASC, a.period ASC, a.module_id ASC "
);
while(list.next()) {
	list.put("join_rate", m.nf(list.i("u_cnt") > 0 ? list.d("s_cnt") / list.i("u_cnt") * 100 : 0.0, 1));
	list.put("eva_rate", m.nf(list.i("s_cnt") > 0 ? list.d("c_cnt") / list.i("s_cnt") * 100 : 0.0, 1));
	list.put("u_cnt", m.nf(list.i("u_cnt")));
	list.put("s_cnt", m.nf(list.i("s_cnt")));
	list.put("c_cnt", m.nf(list.i("c_cnt")));

	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), forum.onoffTypes));
	if("1".equals(applyType)) { //기간
		list.put("start_date_conv", m.time("yyyy-MM-dd", list.s("start_date")));
		list.put("start_date_hour", m.time("HH", list.s("start_date")));
		list.put("start_date_min", m.time("mm", list.s("start_date")));
		list.put("end_date_conv", m.time("yyyy-MM-dd", list.s("end_date")));
		list.put("end_date_hour", m.time("HH", list.s("end_date")));
		list.put("end_date_min", m.time("mm", list.s("end_date")));

		list.put("apply_type_1", true);
		list.put("apply_type_2", false);
	} else if("2".equals(applyType)) { //차시
		list.put("apply_type_1", false);
		list.put("apply_type_2", true);
	}
}

//출력
p.setBody("management.forum_list");
p.setVar("p_title", ptitle);
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,mode"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total_count", list.size());

p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes(10));
p.display();
%>