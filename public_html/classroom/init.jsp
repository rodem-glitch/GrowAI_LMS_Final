<%@ include file="../init.jsp"%><%

//로그인
if(1 > userId) { auth.loginForm(); return; }

//기본키
int cuid = m.ri("cuid");
if(cuid == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
UserDao user = new UserDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseModuleDao courseModule = new CourseModuleDao();

CourseUserDao cu = new CourseUserDao();
CourseModuleDao cm = new CourseModuleDao();

//변수
String today = m.time("yyyyMMdd");
String now = m.time("yyyyMMddHHmmss");

//정보
DataSet cuinfo = courseUser.query(
	"SELECT a.*, c.course_nm, c.course_type, c.onoff_type, c.sms_yn, c.limit_seek_yn, t.user_nm tutor_name, c.subject_id, c.renew_max_cnt, c.renew_yn, u.id user_id, u.user_nm, u.mobile "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id"
	+ " LEFT JOIN " + user.table + " t ON a.tutor_id = t.id"
	+ " WHERE a.id = " + cuid + " AND a.user_id = '" + userId + "' AND a.status IN (1,3)"
);
if(!cuinfo.next()) { m.jsError(_message.get("alert.course_user.nodata")); return; }

//정보-과정
String courseId = cuinfo.s("course_id");
DataSet cinfo = course.find("id = " + courseId + " AND site_id = " + siteId + "");
if(!cinfo.next()) { m.jsError(_message.get("alert.course.nodata")); return; }
cinfo.put("lesson_time_conv", m.nf((int)cinfo.d("lesson_time")));
cinfo.put("onoff_type_conv", m.getValue(cinfo.s("onoff_type"), course.onoffTypesMsg));
cinfo.put("std_progress", m.nf(cinfo.i("assign_progress") * cinfo.i("limit_progress") / 100, 1));
cinfo.put("std_exam", m.nf(cinfo.i("assign_exam") * cinfo.i("limit_exam") / 100, 1));
cinfo.put("std_homework", m.nf(cinfo.i("assign_homework") * cinfo.i("limit_homework") / 100, 1));
cinfo.put("std_forum", m.nf(cinfo.i("assign_forum") * cinfo.i("limit_forum") / 100, 1));
cinfo.put("std_etc", m.nf(cinfo.i("assign_etc") * cinfo.i("limit_etc") / 100, 1));

boolean alltime = "A".equals(cuinfo.s("course_type"));
cinfo.put("alltime_block", alltime);

//상태 [progress] (W : 대기, E : 종료, I : 수강중, R : 복습중)
cuinfo.put("restudy_edate", cuinfo.s("end_date"));
cuinfo.put("restudy_block", false);
String progress = "I";
if(0 > m.diffDate("D", cuinfo.s("start_date"), today)) progress = "W"; //대기
else if(0 >= m.diffDate("D", cuinfo.s("end_date"), today)) progress = "I"; //수강중
else {
	if(cinfo.b("restudy_yn")) {  //복습
		progress = "R";
		cuinfo.put("restudy_edate", m.addDate("D", cinfo.i("restudy_day"), cuinfo.s("end_date"), "yyyyMMdd"));
		cuinfo.put("restudy_block", true);
	} else progress = "E"; //종료
}
cuinfo.put("restudy_edate_conv", m.time(_message.get("format.date.dot"), cuinfo.s("restudy_edate")));
cuinfo.put("progress", progress);
cuinfo.put("status_conv", m.getValue(progress, courseUser.progressListMsg));
if("Y".equals(cuinfo.s("close_yn"))) cuinfo.put("status_conv", "마감");

cuinfo.put("tutor_name", !"".equals(cuinfo.s("tutor_name")) ? cuinfo.s("tutor_name") : "-");
cuinfo.put("start_date_conv", m.time(_message.get("format.date.dot"), cuinfo.s("start_date")));
cuinfo.put("end_date_conv", m.time(_message.get("format.date.dot"), cuinfo.s("end_date")));
cuinfo.put("past_day", m.diffDate("D", cuinfo.s("start_date"), today));  //경과일

cuinfo.put("total_score_conv", m.nf(cuinfo.d("total_score"), 1));
cuinfo.put("progress_ratio", m.nf(cuinfo.d("progress_ratio"), 1));
cuinfo.put("progress_ratio_conv", m.nf(cuinfo.d("progress_ratio"), 1));
cuinfo.put("exam_value_conv", m.nf(cuinfo.d("exam_value"), 1));
cuinfo.put("homework_value_conv", m.nf(cuinfo.d("homework_value"), 1));
cuinfo.put("forum_value_conv", m.nf(cuinfo.d("forum_value"), 1));
cuinfo.put("etc_value_conv", m.nf(cuinfo.d("etc_value"), 1));

cuinfo.put("progress_score_conv", m.nf(cuinfo.d("progress_score"), 1));
cuinfo.put("exam_score_conv", m.nf(cuinfo.d("exam_score"), 1));
cuinfo.put("homework_score_conv", m.nf(cuinfo.d("homework_score"), 1));
cuinfo.put("forum_score_conv", m.nf(cuinfo.d("forum_score"), 1));
cuinfo.put("etc_score_conv", m.nf(cuinfo.d("etc_score"), 1));


//채널
String ch = "classroom";

p.setVar("cuinfo", cuinfo);
p.setVar("course", cinfo);

%>