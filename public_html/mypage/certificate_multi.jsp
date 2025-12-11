<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String idx = m.join(",", f.getArr("idx"));
if("".equals(idx)) { m.jsErrClose(_message.get("alert.common.required_key")); return; }

String type = m.rs("type");

//PDF출력
/*
if(!"html".equals(type)) {
	String url = webUrl + "/mypage/certificate_multi.jsp?type=html&idx=" + idx;
	String path = dataDir + "/tmp/" + m.getUniqId() + ".pdf";
	String cmd = "/usr/local/bin/wkhtmltopdf -s A4 "
		+ " --cookie MLMS14" + siteId + "7 " + m.getCookie("MLMS14" + siteId + "7")
		+ (siteId > 1 ? " --disable-smart-shrinking " : "")
		+ " " + url + " " + path;
	
	m.exec(cmd);
	m.output(path, null);
	m.delFile(path);
	return;
}
*/

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseLessonDao courseLesson = new CourseLessonDao();
UserDeptDao userDept = new UserDeptDao();

TutorDao tutor = new TutorDao();
CourseTutorDao courseTutor = new CourseTutorDao();

OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();

FileDao file = new FileDao();

//정보
//courseUser.d(out);
DataSet list = courseUser.query(
	" SELECT a.*, b.course_nm, b.course_type, b.onoff_type, b.lesson_time, b.year, b.step, b.course_address, b.credit, b.etc1 course_etc1, b.etc2 course_etc2 "
	+ " , c.login_id, c.dept_id, c.user_nm, c.birthday, c.zipcode, c.new_addr, c.addr_dtl, c.gender, c.etc1, c.etc2, c.etc3, c.etc4, c.etc5 "
	+ " , d.dept_nm, oi.pay_price, oi.refund_price "
	+ " , (SELECT COUNT(*) FROM " + courseLesson.table + " WHERE course_id = a.course_id AND status = 1) lesson_cnt "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " b ON a.course_id = b.id AND b.cert_complete_yn = 'Y' "
	+ " LEFT JOIN " + orderItem.table + " oi ON a.order_item_id = oi.id AND oi.status IN (1, 3) "
	+ " LEFT JOIN " + order.table + " o ON a.order_id = o.id AND oi.order_id = o.id AND o.status IN (1, 3) "
	+ " INNER JOIN " + user.table + " c ON a.user_id = c.id AND c.status != -1 "
	+ " LEFT JOIN " + userDept.table + " d ON c.dept_id = d.id "
	+ " WHERE a.id IN (" + idx + ") AND a.complete_yn = 'Y' "
	+ " AND a.user_id = " + userId + " AND a.status IN (1, 3) "
	+ " ORDER BY a.id DESC "
);
if(0 == list.size()) { m.jsErrClose(_message.get("alert.course_user.nodata_complete")); return; }

//변수
String courseEtc1 = "";
String courseEtc2 = "";
String totalStartDate = "";
String totalEndDate = "";
double totalLessonTime = 0.0;

//포맷팅
while(list.next()) {

	if(0 < list.i("dept_id")) {	
		list.put("dept_nm_conv", userDept.getNames(list.i("dept_id")));
	} else {	
		list.put("dept_nm", "[미소속]");
		list.put("dept_nm_conv", "[미소속]");
	}	

	list.put("lesson_time_conv", m.nf((int)list.d("lesson_time")));

	list.put("lesson_time_hour", (int)Math.floor(list.d("lesson_time")));
	list.put("lesson_time_min", (int)Math.round((list.d("lesson_time") - Math.floor(list.d("lesson_time"))) * 60));

	list.put("birthday_conv", m.time(_message.get("format.date.local"), list.s("birthday")));
	list.put("birthday_conv2", m.time(_message.get("format.date.dot"), list.s("birthday")));
	list.put("birthday_conv3", m.time(_message.get("format.dateshort.dot"), list.s("birthday")));

	list.put("gender_conv", m.getValue(list.s("gender"), user.gendersMsg));

	list.put("onoff_type_conv", m.getValue(list.s("onoff_type"), course.onoffTypesMsg));
	list.put("start_date_conv", m.time(_message.get("format.date.local"), list.s("start_date")));
	list.put("start_date_conv2", m.time(_message.get("format.date.dot"), list.s("start_date")));
	list.put("start_date_conv3", m.time(_message.get("format.dateshort.dot"), list.s("start_date")));
	list.put("end_date_year", m.time("yyyy", list.s("end_date")));
	list.put("end_date_conv", m.time(_message.get("format.date.local"), list.s("end_date")));
	list.put("end_date_conv2", m.time(_message.get("format.date.dot"), list.s("end_date")));
	list.put("end_date_conv3", m.time(_message.get("format.dateshort.dot"), list.s("end_date")));
	list.put("course_nm_conv", m.cutString(m.htmlToText(list.s("course_nm")), 48));

	list.put("progress_ratio_conv", m.nf(list.d("progress_ratio"), 1));
	list.put("total_score", m.nf(list.d("total_score"), 0));
	list.put("complete_year", m.time("yyyy", list.s("complete_date")));
	list.put("complete_date_conv", m.time(_message.get("format.date.local"), list.s("complete_date")));
	list.put("complete_date_conv2", m.time(_message.get("format.date.dot"), list.s("complete_date")));
	list.put("complete_date_conv3", m.time(_message.get("format.dateshort.dot"), list.s("complete_date")));

	list.put("pay_price_conv", m.nf(list.i("pay_price") - list.i("refund_price")));
	list.put("certificate_no", m.time(_message.get("format.date.dot"), list.s("start_date")) + "-" + m.strrpad(list.i("id") + "", 5, "0"));
	list.put("today", m.time(_message.get("format.date.local"), list.s("complete_date")));
	list.put("today2", m.time(_message.get("format.date.dot"), list.s("complete_date")));
	list.put("today3", m.time(_message.get("format.dateshort.dot"), list.s("complete_date")));

	if("".equals(totalStartDate) || 0 > m.diffDate("D", totalStartDate, list.s("start_date"))) totalStartDate = list.s("start_date");
	if("".equals(totalEndDate) || 0 < m.diffDate("D", totalEndDate, list.s("end_date"))) totalEndDate = list.s("end_date");

	totalLessonTime = totalLessonTime + list.d("lesson_time");

	//강사
	DataSet tutors = courseTutor.query(
		"SELECT t.*, u.display_yn "
		+ " FROM " + courseTutor.table + " a "
		+ " LEFT JOIN " + tutor.table + " t ON a.user_id = t.user_id "
		+ " LEFT JOIN " + user.table + " u ON t.user_id = u.id "
		+ " WHERE a.course_id = " + list.i("course_id") + " "
		+ " ORDER BY t.tutor_nm ASC "
	);
	list.put(".tutors", tutors);
	
	//정보-파일
	DataSet files = file.getFileList(list.i("user_id"), "user", true);
	while(files.next()) {
		files.put("image_block", -1 < files.s("filetype").indexOf("image/"));
		files.put("file_url", m.getUploadUrl(files.s("filename")));
	}
	list.put(".files", files);

	if(1 > list.getIndex()) {
		courseEtc1 = list.s("course_etc1");
		courseEtc2 = list.s("course_etc2");
	}
}

uinfo.put("birthday_conv", m.time(_message.get("format.date.local"), uinfo.s("birthday")));
uinfo.put("birthday_conv2", m.time(_message.get("format.date.dot"), uinfo.s("birthday")));
uinfo.put("birthday_conv3", m.time(_message.get("format.dateshort.dot"), uinfo.s("birthday")));

//출력
p.setLayout(null);
p.setBody("page.certificate_multi");
p.setVar("user", uinfo);

p.setVar(list);
p.setLoop("list", list);

p.setVar("course_cnt", list.size());
p.setVar("total_start_date_conv", m.time(_message.get("format.date.local"), totalStartDate));
p.setVar("total_start_date_conv2", m.time(_message.get("format.date.dot"), totalStartDate));
p.setVar("total_start_date_conv3", m.time(_message.get("format.dateshort.dot"), totalStartDate));
p.setVar("total_end_date_conv", m.time(_message.get("format.date.local"), totalEndDate));
p.setVar("total_end_date_conv2", m.time(_message.get("format.date.dot"), totalEndDate));
p.setVar("total_end_date_conv3", m.time(_message.get("format.dateshort.dot"), totalEndDate));
p.setVar("total_lesson_time", totalLessonTime + "");
p.setVar("total_lesson_time_conv", m.nf((int)totalLessonTime));
p.setVar("total_lesson_time_hour", (int)Math.floor(totalLessonTime));
p.setVar("total_lesson_time_min", (int)Math.round((totalLessonTime - Math.floor(totalLessonTime)) * 60));

p.setVar("today", m.time(_message.get("format.date.local")));
p.setVar("today2", m.time(_message.get("format.date.dot")));
p.setVar("today3", m.time(_message.get("format.dateshort.dot")));

p.setVar("course_etc1", courseEtc1);
p.setVar("course_etc2", courseEtc2);
p.setVar("certificate_multi_file_url", m.getUploadUrl(siteinfo.s("certificate_multi_file")));

p.display();

%>