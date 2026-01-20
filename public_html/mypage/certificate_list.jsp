<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CourseUserDao courseUser = new CourseUserDao();
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");

//변수
String type = m.rs("type");
String today = m.time("yyyyMMdd");
boolean isCertCourse = false;
boolean isCertComplete = false;
boolean isPassComplete = false;

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " LEFT JOIN " + category.table + " ct ON c.category_id = ct.id AND ct.module = 'course' AND ct.status = 1 "
);
lm.setFields("a.*, c.course_nm, c.course_type, c.onoff_type, c.cert_course_yn, c.cert_complete_yn, c.pass_yn, c.credit, c.cert_template_id, c.pass_cert_template_id, ct.category_nm");
if(!"".equals(type)) lm.addWhere("c.onoff_type " + ("on".equals(type) ? "=" : "!=") + " 'N'");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("a.user_id = " + userId + "");
lm.setOrderBy("a.start_date DESC");

//목록
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("start_date_conv", m.time(_message.get("format.date.dot"), list.s("start_date")));
	list.put("end_date_conv", m.time(_message.get("format.date.dot"), list.s("end_date")));
	list.put("study_date_conv", list.s("start_date_conv") + " - " + list.s("end_date_conv"));
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 40));
	list.put("progress_ratio", m.nf(list.d("progress_ratio"), 1));
	list.put("total_score", m.nf(list.d("total_score"), 1));
	//list.put("type_conv", m.getValue(list.s("course_type"), course.typesMsg));
	list.put("type_conv", m.getValue(list.s("onoff_type"), course.onoffTypesMsg));
	list.put("ready_block", 0 > m.diffDate("D", list.s("start_date"), today));
	list.put("template_block", 0 < list.i("cert_template_id"));
	list.put("pass_template_block", 0 < list.i("pass_cert_template_id"));
	list.put("pass_cert_block", list.b("complete_yn") && "P".equals(list.s("complete_status")));
	if(!isCertCourse && list.b("cert_course_yn")) isCertCourse = true;
	if(!isCertComplete && list.b("cert_complete_yn")) isCertComplete = true;
	if(!isPassComplete && "Y".equals(list.s("pass_yn"))) isPassComplete = true;
}



//출력
p.setLayout("mypage_newmain");
p.setBody("mypage.certificate_list");
p.setVar("p_title", "증명서발급");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("login_block", true);
p.setVar("SYS_USERNAME", uinfo.s("user_nm"));
String userNameForHeader = uinfo.s("user_nm");
p.setVar("SYS_USERNAME_INITIAL", userNameForHeader.length() > 0 ? userNameForHeader.substring(0, 1) : "?");
p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());

p.setVar("cert_course_block", isCertCourse);
p.setVar("cert_complete_block", isCertComplete);
p.setVar("pass_complete_block", isPassComplete);
p.setVar("LNB_CERTIFICATE", "select");
p.display();

%>
