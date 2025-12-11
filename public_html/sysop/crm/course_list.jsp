<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CoursePackageDao coursePackage = new CoursePackageDao();

//제한-회원
if(1 > user.findCount("id = ? AND site_id = " + siteId + " AND status != -1", new Object[] {uid})) { m.jsAlert("해당 회원정보가 없습니다."); return; }

//변수
String today = m.time("yyyyMMdd");

//폼체크
f.addElement("s_listnum", null, null);
f.addElement("crm_course_id", null, "hname:'등록과정', required:'Y'");
f.addElement("crm_course_nm", null, "hname:'등록과정', required:'Y'");

//수강신청
if(m.isPost() && f.validate()) {

	//정보
	DataSet cinfo = course.find("id = " + f.get("crm_course_id") + " AND site_id = " + siteId + " AND status != -1");
	if(!cinfo.next()) { m.jsAlert("해당 과정정보가 없습니다."); return; }

	//수강신청
	if(!"P".equals(cinfo.s("onoff_type"))) {
		if(!courseUser.addUser(cinfo, f.getInt("uid"), 1)) { m.jsAlert("수강생을 등록하는 중 오류가 발생했습니다."); return; }
	} else {
		DataSet sub = coursePackage.getCourses(cinfo.i("id"));
		while(sub.next()) {
			if(!courseUser.addUser(sub, f.getInt("uid"), 1, cinfo)) { m.jsAlert("수강생을 등록하는 중 오류가 발생했습니다."); return; }
		}
	}

	//이동
	m.jsAlert(f.get("crm_course_nm") + "\\n과정에 등록되었습니다.");
	m.jsReplace("course_list.jsp?" + m.qs(), "parent");
	return;
}

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 1000000 : f.getInt("s_listnum", 20));
lm.setTable(
	courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id AND u.status != -1 "
);
lm.setFields("a.*, c.course_nm, c.course_type, c.year, c.step, c.lesson_time");
lm.addWhere("a.user_id = " + uid);
if("C".equals(userKind)) lm.addWhere("a.course_id IN (" + manageCourses + ")");
if(!"end".equals(m.rs("mode"))) {
	//수강중
	lm.addWhere("a.status IN (0, 1, 3)");
	lm.addWhere("a.close_yn = 'N'");
	lm.addWhere("a.end_date >= '" + today + "' ");
	lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.start_date ASC, a.id DESC");
} else {
	//종료
	lm.addWhere("a.status IN (1, 3)");
	lm.addWhere("(a.end_date < '" + today + "' OR a.close_yn = 'Y')");
	lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.end_date DESC, a.id DESC");
}

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("start_date_conv", m.time("yyyy.MM.dd", list.s("start_date")));
	list.put("end_date_conv", m.time("yyyy.MM.dd", list.s("end_date")));
	list.put("study_date_conv", list.s("start_date_conv") + " - " + list.s("end_date_conv"));
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 50));
	list.put("progress_ratio", m.nf(list.d("progress_ratio"), 2));
	list.put("total_score", m.nf(list.d("total_score"), 2));
	list.put("type_conv", m.getItem(list.s("course_type"), course.types));

	if(!"end".equals(m.rs("mode"))) {
		//수강중
		String status = "";
		if(list.i("status") == 0) status = "승인대기";
		else if(0 > m.diffDate("D", list.s("start_date"), today)) status = "학습대기";
		else {
			if(list.b("complete_yn")) status = "수료";
			else status = "학습중";
		}
		list.put("status_conv", status);
	} else {
		//종료
		list.put("status_conv", list.b("complete_yn") ? "수료" : "미수료");
	}
}

//출력
p.setLayout(ch);
p.setBody("crm.course_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("cuid"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("tab_course", "current");
p.setVar("tab_sub_" + (!"end".equals(m.rs("mode")) ? "course" : "end"), "current");
p.display();

%>