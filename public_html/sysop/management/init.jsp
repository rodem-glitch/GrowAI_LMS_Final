<%@ include file="../init.jsp" %><%

String ch = "sysop";

//과정
CourseDao course = new CourseDao();
DataSet cinfo = new DataSet();
int courseId = m.ri("cid");
String ptitle = "";
boolean alltime = false;
if(courseId > 0) {
	cinfo = course.find(
		"id = " + courseId + " AND site_id = " + siteId + " AND status != -1"
		+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
	);
	if(!cinfo.next()) { m.jsAlert("해당 과정정보가 없습니다."); return; }
	ptitle = "<span style='color:#666666'>[" + cinfo.s("year") + "년/" + cinfo.s("step") + "기]</span> "
		+ "<span style='color:#4C5BA9'>" + cinfo.s("course_nm") + "</span>";

	cinfo.put("std_progress", m.nf(cinfo.i("assign_progress") * cinfo.i("limit_progress") / 100, 1));
	cinfo.put("std_exam", m.nf(cinfo.i("assign_exam") * cinfo.i("limit_exam") / 100, 1));
	cinfo.put("std_homework", m.nf(cinfo.i("assign_homework") * cinfo.i("limit_homework") / 100, 1));
	cinfo.put("std_forum", m.nf(cinfo.i("assign_forum") * cinfo.i("limit_forum") / 100, 1));
	cinfo.put("std_etc", m.nf(cinfo.i("assign_etc") * cinfo.i("limit_etc") / 100, 1));

	cinfo.put("study_sdate_conv", m.time("yyyy-MM-dd", cinfo.s("study_sdate")));
	cinfo.put("study_edate_conv", m.time("yyyy-MM-dd", cinfo.s("study_edate")));

	alltime = "A".equals(cinfo.s("course_type"));
	cinfo.put("alltime_block", alltime);

	cinfo.put("attend_block", !"N".equals(cinfo.s("onoff_type")));

	p.setVar("course", cinfo);
}

p.setVar("auth_course_block", Menu.accessible(33, userId, userKind, false));
p.setVar("auth_management_block", Menu.accessible(75, userId, userKind, false));
p.setVar("auth_complete_block", Menu.accessible(76, userId, userKind, false));
p.setVar("auth_auto_block", Menu.accessible(42, userId, userKind, false));

%>