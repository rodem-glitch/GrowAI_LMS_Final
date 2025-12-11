<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int cid = m.ri("cid");
if(cid == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseLessonDao courseLesson = new CourseLessonDao();

TutorDao tutor = new TutorDao();
CourseTutorDao courseTutor = new CourseTutorDao();

OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();

UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();

CertificateTemplateDao certificateTemplate = new CertificateTemplateDao();

FileDao file = new FileDao();

//정보
DataSet list = courseUser.query(
	" SELECT a.*, b.course_nm, b.course_type, b.onoff_type, b.lesson_day, b.lesson_time, b.year, b.step, b.course_address, b.credit, b.etc1 course_etc1, b.etc2 course_etc2, b.cert_template_id "
	+ " , c.login_id, c.dept_id, c.user_nm, c.birthday, c.zipcode, c.new_addr, c.addr_dtl, c.gender, c.etc1, c.etc2, c.etc3, c.etc4, c.etc5 "
	+ " , d.dept_nm, o.pay_date, oi.pay_price, oi.refund_price "
	+ " , (SELECT COUNT(*) FROM " + courseLesson.table + " WHERE course_id = a.course_id AND status = 1) lesson_cnt "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " b ON a.course_id = b.id "
	+ " LEFT JOIN " + orderItem.table + " oi ON a.order_item_id = oi.id AND oi.status IN (1, 3) "
	+ " LEFT JOIN " + order.table + " o ON a.order_id = o.id AND oi.order_id = o.id AND o.status IN (1, 3) "
	+ " INNER JOIN " + user.table + " c ON a.user_id = c.id " + (deptManagerBlock ? " AND c.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "") + " AND c.status != -1 "
	+ " LEFT JOIN " + userDept.table + " d ON c.dept_id = d.id "
	+ " WHERE a.course_id = " + cid + " AND a.complete_yn = 'Y' AND a.status IN (1, 3) "
	+ ("C".equals(userKind) ? " AND a.course_id IN (" + manageCourses + ") " : "")
);
if(0 == list.size()) { m.jsErrClose("수료증 정보가 없습니다."); return; }

DataSet cinfo = course.find("id = ? AND site_id = ? AND status != ? ", new Object[] { cid, siteId, -1 });
if(!cinfo.next()) { m.jsErrClose("해당 과정 정보가 없습니다."); return; }

//이동
if(0 < cinfo.i("cert_template_id")) { m.jsReplace("certificate_template_all.jsp?" + m.qs()); return; }

//포맷팅
while(list.next()) {
	if(0 < list.i("dept_id")) {
		list.put("dept_nm_conv", userDept.getNames(list.i("dept_id")));
	} else {
		list.put("dept_nm", "[미소속]");
		list.put("dept_nm_conv", "[미소속]");
	}

	list.put("lesson_time_conv", m.nf((int)list.d("lesson_time")));

	list.put("birthday_conv", m.time("yyyy년 MM월 dd일", list.s("birthday")));
	list.put("birthday_conv2", m.time("yyyy.MM.dd", list.s("birthday")));
	list.put("birthday_conv3", m.time("yy.MM.dd", list.s("birthday")));

	list.put("gender_conv", m.getItem(list.s("gender"), user.genders));

	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffTypes));
	list.put("start_date_conv", m.time("yyyy년 MM월 dd일", list.s("start_date")));
	list.put("start_date_conv2", m.time("yyyy.MM.dd", list.s("start_date")));
	list.put("end_date_year", m.time("yyyy", list.s("end_date")));
	list.put("end_date_conv", m.time("yyyy년 MM월 dd일", list.s("end_date")));
	list.put("end_date_conv2", m.time("yyyy.MM.dd", list.s("end_date")));
	list.put("course_nm_conv", m.cutString(m.htmlToText(list.s("course_nm")), 48));

	list.put("progress_ratio_conv", m.nf(list.d("progress_ratio"), 1));
	list.put("total_score", m.nf(list.d("total_score"), 0));
	list.put("complete_year", m.time("yyyy", list.s("complete_date")));
	list.put("complete_date_conv", m.time("yyyy년 MM월 dd일", list.s("complete_date")));
	list.put("complete_date_conv2", m.time("yyyy.MM.dd", list.s("complete_date")));

	if(!"".equals(list.s("pay_date"))) {
		list.put("pay_date_conv", m.time(_message.get("format.date.local"), list.s("pay_date")));
		list.put("pay_date_conv2", m.time(_message.get("format.date.dot"), list.s("pay_date")));
		list.put("pay_date_conv3", m.time(_message.get("format.dateshort.dot"), list.s("pay_date")));
	} else {
		list.put("pay_date_conv", "-");
		list.put("pay_date_conv2", "-");
		list.put("pay_date_conv3", "-");
	}

	list.put("pay_price_conv", m.nf(list.i("pay_price") - list.i("refund_price")));
	list.put("certificate_no", m.time("yyyy.MM.dd", list.s("start_date")) + "-" + m.strrpad(list.s("id") + "", 5, "0"));
	list.put("today", m.time("yyyy년 MM월 dd일", list.s("complete_date")));
	list.put("today2", m.time("yyyy.MM.dd", list.s("complete_date")));

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
	user.maskInfo(list);
}

m.jsAlert("총 " + list.size() + "장의 수료증을 출력합니다.");

//기록-개인정보조회
if(list.size() > 0 && !isBlindUser) _log.add("V", "수료증일괄출력", list.size(), "이러닝 운영", list);

//출력
p.setRoot(siteinfo.s("doc_root") + "/html");
p.setLayout(null);
p.setBody("page.certificate");

p.setLoop("list", list);

p.setVar("single_block", true);
p.setVar("certificate_file_url", (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(siteinfo.s("certificate_file")));
p.display();

%>