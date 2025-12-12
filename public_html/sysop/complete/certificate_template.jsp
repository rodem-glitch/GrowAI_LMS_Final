<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("cuid");
if(id == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }
String certType = m.rs("type");

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseLessonDao courseLesson = new CourseLessonDao();

TutorDao tutor = new TutorDao();
CourseTutorDao courseTutor = new CourseTutorDao();

OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();

UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

CertificateTemplateDao certificateTemplate = new CertificateTemplateDao();
FileDao file = new FileDao();

//정보
DataSet info = courseUser.query(
    " SELECT a.* "
	+ ", b.course_nm, b.course_type, b.onoff_type, b.lesson_day, b.lesson_time, b.year, b.step, b.course_address, b.credit, b.cert_template_id, b.pass_cert_template_id "
	+ ", b.etc1 course_etc1, b.etc2 course_etc2 "
	+ ", c.login_id, c.dept_id, c.user_nm, c.birthday, c.zipcode, c.new_addr, c.addr_dtl, c.gender, c.etc1, c.etc2, c.etc3, c.etc4, c.etc5 "
	+ ", d.dept_nm, o.pay_date, oi.pay_price, oi.refund_price "
	+ ", (SELECT COUNT(*) FROM " + courseLesson.table + " WHERE course_id = a.course_id AND status = 1) lesson_cnt "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " b ON a.course_id = b.id "
	+ " LEFT JOIN " + orderItem.table + " oi ON a.order_item_id = oi.id AND oi.status IN (1, 3) "
	+ " LEFT JOIN " + order.table + " o ON a.order_id = o.id AND oi.order_id = o.id AND o.status IN (1, 3) "
	+ " INNER JOIN " + user.table + " c "
		+ " ON a.user_id = c.id " + (deptManagerBlock ? " AND c.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "") + " AND c.status != -1 "
	+ " LEFT JOIN " + userDept.table + " d ON c.dept_id = d.id "
	+ " WHERE a.id = " + id + " AND a.complete_yn = 'Y' AND a.status IN (1, 3) "
	+ ("P".equals(certType) ? " AND a.complete_status = 'P' " : ("C".equals(certType) ? " AND a.complete_status = 'C' " : " AND a.complete_status IN ('C','P') "))
	+ ("C".equals(userKind) ? " AND a.course_id IN (" + manageCourses + ") " : "")
);
if(!info.next()) { m.jsErrClose("해당 정보가 없습니다."); return; }

int targetTemplateId = "P".equals(certType) ? info.i("pass_cert_template_id") : info.i("cert_template_id");

//이동
if(targetTemplateId == 0) { m.jsReplace("certificate.jsp?" + m.qs()); return; }

//정보
String templateTypeFilter = "P".equals(certType) ? "P" : "C";
DataSet ctinfo = certificateTemplate.find("id = " + targetTemplateId + " AND template_type = '" + templateTypeFilter + "' AND site_id = " + siteId + " AND status != -1");
if(!ctinfo.next()) { m.jsErrClose("해당 수료증템플릿 정보가 없습니다."); return; }

//포맷팅
if(0 < info.i("dept_id")) {
    info.put("dept_nm_conv", userDept.getNames(info.i("dept_id")));
} else {
    info.put("dept_nm", "[미소속]");
    info.put("dept_nm_conv", "[미소속]");
}

info.put("lesson_time_conv", m.nf((int)info.d("lesson_time")));

info.put("birthday_conv", m.time(_message.get("format.date.local"), info.s("birthday")));
info.put("birthday_conv2", m.time(_message.get("format.date.dot"), info.s("birthday")));
info.put("birthday_conv3", m.time(_message.get("format.dateshort.dot"), info.s("birthday")));

info.put("gender_conv", m.getItem(info.s("gender"), user.genders));

info.put("onoff_type_conv", m.getItem(info.s("onoff_type"), course.onoffTypes));
info.put("start_date_conv", m.time(_message.get("format.date.local"), info.s("start_date")));
info.put("start_date_conv2", m.time(_message.get("format.date.dot"), info.s("start_date")));
info.put("start_date_conv3", m.time(_message.get("format.dateshort.dot"), info.s("start_date")));
info.put("end_date_year", m.time("yyyy", info.s("end_date")));
info.put("end_date_conv", m.time(_message.get("format.date.local"), info.s("end_date")));
info.put("end_date_conv2", m.time(_message.get("format.date.dot"), info.s("end_date")));
info.put("end_date_conv3", m.time(_message.get("format.dateshort.dot"), info.s("end_date")));
info.put("course_nm_conv", m.cutString(m.htmlToText(info.s("course_nm")), 48));

info.put("progress_ratio_conv", m.nf(info.d("progress_ratio"), 1));
info.put("total_score", m.nf(info.d("total_score"), 0));
info.put("complete_year", m.time("yyyy", info.s("complete_date")));
info.put("complete_date_conv", m.time(_message.get("format.date.local"), info.s("complete_date")));
info.put("complete_date_conv2", m.time(_message.get("format.date.dot"), info.s("complete_date")));
info.put("complete_date_conv3", m.time(_message.get("format.dateshort.dot"), info.s("complete_date")));

if(!"".equals(info.s("pay_date"))) {
    info.put("pay_date_conv", m.time(_message.get("format.date.local"), info.s("pay_date")));
    info.put("pay_date_conv2", m.time(_message.get("format.date.dot"), info.s("pay_date")));
    info.put("pay_date_conv3", m.time(_message.get("format.dateshort.dot"), info.s("pay_date")));
} else {
    info.put("pay_date_conv", "-");
    info.put("pay_date_conv2", "-");
    info.put("pay_date_conv3", "-");
}

info.put("pay_price_conv", m.nf(info.i("pay_price") - info.i("refund_price")));
info.put("certificate_no", m.time("yyyy.MM.dd", info.s("start_date")) + "-" + m.strrpad(id + "", 5, "0"));
info.put("today", m.time(_message.get("format.date.local"), sysToday));
info.put("today2", m.time(_message.get("format.date.dot"), sysToday));
info.put("today3", m.time(_message.get("format.dateshort.dot"), sysToday));

//포맷팅
info.put("certificate_file_url", (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(ctinfo.s("background_file")));

//강사
DataSet tutors = courseTutor.query(
    "SELECT t.*, u.display_yn "
	+ " FROM " + courseTutor.table + " a "
	+ " LEFT JOIN " + tutor.table + " t ON a.user_id = t.user_id "
	+ " LEFT JOIN " + user.table + " u ON t.user_id = u.id "
	+ " WHERE a.course_id = " + info.i("course_id") + " "
	+ " ORDER BY t.tutor_nm ASC "
);

//정보-파일
DataSet files = file.getFileList(info.i("user_id"), "user", true);
while(files.next()) {
    files.put("image_block", -1 < files.s("filetype").indexOf("image/"));
    files.put("file_url", m.getUploadUrl(files.s("filename")));
}

//출력
p.setVar(info);
p.setLoop("list", info);
p.setLoop("tutors", tutors);
p.setLoop("files", files);

p.setVar("single_block", true);
p.setVar("cert_title", "P".equals(certType) ? "합격증" : "수료증");
String tbody = certificateTemplate.fetchTemplate(siteId, ctinfo.s("template_cd"), p);

out.print(tbody);
%>
<script>
window.onload = function() {
	try {
		window.print();
	} catch (e) {
		console.log(e.message);
		alert("인쇄할 수 없습니다.");
	}
}
</script>
