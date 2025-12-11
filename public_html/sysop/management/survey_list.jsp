<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();
SurveyDao survey = new SurveyDao();
SurveyUserDao surveyUser = new SurveyUserDao();
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
	DataSet info = survey.find("id = " + id + " AND status = 1 AND site_id = " + siteId + "");
	if(!info.next()) { m.jsAlert("해당 정보가 없습니다."); return; }

	//제한
	/*
	if(cinfo.i("assign_survey") > 0 && info.i("assign_score") > 0) {
		m.jsAlert("해당 설문이 삭제되면 배점비율과 각 시험의 배점합이 맞지 않게 됩니다. 배점을 0으로 수정한 다음 삭제해야 합니다."); return;
	}
	*/

	//제한
	/*
	if(0 < surveyUser.findCount("survey_id = " + id + " AND course_id = " + courseId + "")) {
		m.jsAlert("참여내역이 있습니다. 삭제할 수 없습니다."); return;
	}
	*/

	//삭제
	if(!courseModule.delete("course_id = " + courseId + " AND module = 'survey' AND module_id = " + id + "")) {
		m.jsAlert("삭제하는 중 오류가 발생했습니다."); return;
	}

	m.jsAlert("삭제되었습니다.");
	m.jsReplace("survey_list.jsp?" + m.qs("id,mode"), "parent");
	return;
}

//수정
if("mod".equals(m.rs("mode")) && m.isPost()) {
	DataSet surveys = f.getArrList(
		"id,apply_type"
		+ ",start_date,start_date_hour,start_date_min,end_date,end_date_hour,end_date_min"
		+ ",chapter"
	);

	//제한
	if(surveys.size() == 0) {	m.jsAlert("수정할 설문이 없습니다."); return; }

	while(surveys.next()) {
		courseModule.item("assign_score", 0);
		courseModule.item("apply_type", applyType);
		if("1".equals(applyType)) {
			String sdate = m.time("yyyyMMdd", surveys.s("start_date")) + surveys.s("start_date_hour") + surveys.s("start_date_min") + "00";
			String edate = m.time("yyyyMMdd", surveys.s("end_date")) + surveys.s("end_date_hour") + surveys.s("end_date_min") + "59";
			courseModule.item("start_date", sdate);
			courseModule.item("end_date", edate);
			courseModule.item("chapter", 0);
		} else if("2".equals(applyType)) {
			courseModule.item("start_date", "");
			courseModule.item("end_date", "");
			courseModule.item("chapter", surveys.i("chapter"));
		}
		if(!courseModule.update("course_id = " + courseId + " AND module = 'survey' AND module_id = " + surveys.i("id") + "")) {}
	}

	m.jsAlert("수정되었습니다.");
	m.jsReplace("survey_list.jsp?" + m.qs("id,mode"), "parent");
	return;
}

//목록
DataSet list = courseModule.query(
	"SELECT a.*, s.id, s.survey_nm "
	+ ", ( "
		+ " SELECT COUNT(*) FROM " + courseUser.table + " cu "
		+ " INNER JOIN " + user.table + " u ON u.id = cu.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
		+ " WHERE cu.course_id = a.course_id AND cu.status IN (1,3) "
	+ " ) u_cnt "
	+ ", ( "
		+ " SELECT COUNT(*) FROM " + surveyUser.table + " u "
		+ " INNER JOIN " + courseUser.table + " c ON c.id = u.course_user_id AND c.status IN (1,3) "
		+ " INNER JOIN " + user.table + " v ON v.id = c.user_id " + (deptManagerBlock ? " AND v.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
		+ " WHERE u.survey_id = a.module_id AND u.course_id = a.course_id "
		+ " AND u.status = 1 "
	+ " ) s_cnt "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + survey.table + " s ON a.module_id = s.id AND s.status != -1 "
	+ " WHERE a.status = 1 AND a.module = 'survey' "
	+ " AND a.course_id = " + courseId + " AND s.site_id = " + siteId + " "
	+ " ORDER BY a.start_date ASC, a.period ASC "
);
while(list.next()) {
	list.put("survey_rate", m.nf(list.i("u_cnt") > 0 ? list.d("s_cnt") / list.i("u_cnt") * 100 : 0.0, 1));
	list.put("u_cnt", m.nf(list.i("u_cnt")));
	list.put("s_cnt", m.nf(list.i("s_cnt")));

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
p.setBody("management.survey_list");
p.setVar("p_title", ptitle);
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total_count", list.size());

p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes(10));
p.display();

%>