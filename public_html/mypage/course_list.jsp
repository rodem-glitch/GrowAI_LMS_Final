<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CourseUserDao courseUser = new CourseUserDao();
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");
PolyStudentDao polyStudent = new PolyStudentDao();
PolyCourseDao polyCourse = new PolyCourseDao();
PolyMemberKeyDao polyMemberKey = new PolyMemberKeyDao();

//변수
String type = m.rs("type");
String today = m.time("yyyyMMdd");
String ord = m.rs("ord", "id desc");
ord = m.getItem(ord.toLowerCase(), new String[] {
	"id desc=>a.id desc", "id asc=>a.id asc", "cn asc=>c.course_nm asc", "cn desc=>c.course_nm desc"
	, "sd asc=>a.start_date asc", "sd desc=>a.start_date desc", "ed asc=>a.end_date asc", "ed desc=>a.end_date desc"
});
if("".equals(ord)) ord = "a.id desc";

//폼체크
f.addElement("ord", null, null);

//===== 비정규(LMS) 수강중인 과정 =====
DataSet list1_prism = courseUser.query(
	" SELECT a.*, c.year, c.step, c.course_nm, c.course_type, c.onoff_type, c.course_file, c.credit, c.lesson_time, c.renew_max_cnt, c.renew_yn, c.mobile_yn, ct.category_nm "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " LEFT JOIN " + category.table + " ct ON c.category_id = ct.id AND ct.module = 'course' AND ct.status = 1 "
	+ " WHERE a.user_id = " + userId + " AND a.status IN (0, 1, 3) "
	+ (!"".equals(type) ? " AND c.onoff_type " + ("on".equals(type) ? "=" : "!=") + " 'N' " : "")
	+ " AND a.close_yn = 'N' AND a.end_date >= '" + today + "' "
	+ " ORDER BY " + ord + ", a.id DESC "
);
while(list1_prism.next()) {
	list1_prism.put("start_date_conv", m.time(_message.get("format.date.dot"), list1_prism.s("start_date")));
	list1_prism.put("end_date_conv", m.time(_message.get("format.date.dot"), list1_prism.s("end_date")));
	list1_prism.put("study_date_conv", list1_prism.s("start_date_conv") + " - " + list1_prism.s("end_date_conv"));
	list1_prism.put("course_nm_conv", m.cutString(list1_prism.s("course_nm"), 40));
	list1_prism.put("progress_ratio", m.nf(list1_prism.d("progress_ratio"), 1).replace(".0", ""));
	list1_prism.put("total_score", m.nf(list1_prism.d("total_score"), 1).replace(".0", ""));
	list1_prism.put("type_conv", m.getValue(list1_prism.s("course_type"), course.typesMsg));
	list1_prism.put("onoff_type_conv", m.getValue(list1_prism.s("onoff_type"), course.onoffTypesMsg));
	list1_prism.put("credit", list1_prism.i("credit"));
	list1_prism.put("mobile_block", list1_prism.b("mobile_yn"));
	list1_prism.put("source_type", "prism");

	list1_prism.put("renew_block", courseUser.setRenewBlock(list1_prism.getRow()));

	if(!"".equals(list1_prism.s("course_file"))) {
		list1_prism.put("course_file_url", m.getUploadUrl(list1_prism.s("course_file")));
	} else {
		list1_prism.put("course_file_url", "/html/images/common/noimage_course.gif");
	}

	String status = "";
	boolean isOpen = false;
	boolean isCancel = false;
	if(list1_prism.i("status") == 0) {
		status = _message.get("list.course_user.etc.waiting_approve");
		if(0 == list1_prism.i("order_id")) isCancel = true;
	} else if(0 > m.diffDate("D", list1_prism.s("start_date"), today)) {
		status = _message.get("list.course_user.etc.waiting_learning");
		isCancel = true;
	} else {
		if(list1_prism.b("complete_yn")) {
			status = _message.get("list.course_user.etc.complete_success");
		} else {
			status = _message.get("list.course_user.etc.learning");
			if(0 == list1_prism.i("order_id")) isCancel = true;
		}
		isOpen = true;
	}

	list1_prism.put("status_conv", status);
	list1_prism.put("open_block", isOpen);
	list1_prism.put("cancel_block", isCancel);
}

//===== 정규(학사) 수강중인 과정 =====
// 왜: 학사 시스템에서 연동된 과목을 LM_POLY_STUDENT + LM_POLY_COURSE 테이블에서 조회합니다.
// 사용자의 login_id를 member_key로 사용하여 매핑합니다.
String memberKey = "";
DataSet memberKeyInfo = polyMemberKey.find("alias_key = '" + uinfo.s("login_id") + "'");
if(memberKeyInfo.next()) {
	memberKey = memberKeyInfo.s("member_key");
} else {
	// 별칭 테이블에 없으면 login_id를 직접 사용
	memberKey = uinfo.s("login_id");
}

String currentYear = m.time("yyyy");
DataSet list1_haksa = polyStudent.query(
	" SELECT s.*, c.course_name, c.course_ename, c.dept_name, c.grad_name, c.week, c.grade "
	+ " , c.curriculum_name, c.category, c.startdate, c.enddate, c.hour1, c.classroom "
	+ " FROM " + polyStudent.table + " s "
	+ " INNER JOIN " + polyCourse.table + " c ON s.course_code = c.course_code "
	+ "   AND s.open_year = c.open_year AND s.open_term = c.open_term "
	+ "   AND s.bunban_code = c.bunban_code AND s.group_code = c.group_code "
	+ " WHERE s.member_key = '" + memberKey + "' "
	+ " AND s.open_year = '" + currentYear + "' "
	+ " ORDER BY c.startdate DESC, c.course_name ASC "
);
while(list1_haksa.next()) {
	// 학습기간 변환
	String startdate = list1_haksa.s("startdate");
	String enddate = list1_haksa.s("enddate");
	if(startdate.length() >= 8) {
		list1_haksa.put("start_date_conv", m.time(_message.get("format.date.dot"), startdate));
	} else {
		list1_haksa.put("start_date_conv", startdate);
	}
	if(enddate.length() >= 8) {
		list1_haksa.put("end_date_conv", m.time(_message.get("format.date.dot"), enddate));
	} else {
		list1_haksa.put("end_date_conv", enddate);
	}
	list1_haksa.put("study_date_conv", list1_haksa.s("start_date_conv") + " - " + list1_haksa.s("end_date_conv"));
	list1_haksa.put("course_nm_conv", m.cutString(list1_haksa.s("course_name"), 40));
	list1_haksa.put("progress_ratio", "0"); // 학사 과목은 진도율 별도 관리
	list1_haksa.put("status_conv", "학습중");
	list1_haksa.put("open_block", true);
	list1_haksa.put("source_type", "haksa");
	list1_haksa.put("onoff_type_conv", "".equals(list1_haksa.s("category")) ? "정규" : list1_haksa.s("category"));
	list1_haksa.put("week_count", !"".equals(list1_haksa.s("week")) ? list1_haksa.s("week") : "15");
	
	// 학사 과목은 강의실 URL 형식이 다름 (course_code 기반)
	String haksaCuid = list1_haksa.s("course_code") + "_" + list1_haksa.s("open_year") 
		+ "_" + list1_haksa.s("open_term") + "_" + list1_haksa.s("bunban_code");
	list1_haksa.put("haksa_cuid", haksaCuid);
}


//종료된 과정
boolean isRestudy = false;
DataSet list2 = courseUser.query(
	"SELECT a.*, c.course_nm, c.course_type, c.restudy_yn, c.restudy_day, c.onoff_type, c.course_file, c.credit, c.lesson_time, c.mobile_yn, c.complete_auto_yn, ct.category_nm "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " LEFT JOIN " + category.table + " ct ON c.category_id = ct.id AND ct.module = 'course' AND ct.status = 1 "
	+ " WHERE a.user_id = " + userId + " AND a.status IN (1, 3) "
	+ (!"".equals(type) ? " AND c.onoff_type " + ("on".equals(type) ? "=" : "!=") + " 'N' " : "")
	+ " AND (a.end_date < '" + today + "' OR a.close_yn = 'Y') "
	+ " ORDER BY " + ord + ", a.id DESC "
);
while(list2.next()) {
	list2.put("start_date_conv", m.time(_message.get("format.date.dot"), list2.s("start_date")));
	list2.put("end_date_conv", m.time(_message.get("format.date.dot"), list2.s("end_date")));
	list2.put("study_date_conv", list2.s("start_date_conv") + " - " + list2.s("end_date_conv"));
	list2.put("course_nm_conv", m.cutString(list2.s("course_nm"), 40));
	list2.put("progress_ratio", m.nf(list2.d("progress_ratio"), 1).replace(".0", ""));
	list2.put("total_score", m.nf(list2.d("total_score"), 1).replace(".0", ""));
	list2.put("type_conv", m.getValue(list2.s("course_type"), course.typesMsg));
	list2.put("onoff_type_conv", m.getValue(list2.s("onoff_type"), course.onoffTypesMsg));

	String status = "";
	if("P".equals(list2.s("complete_status"))) {
		status = "합격";
	} else if("C".equals(list2.s("complete_status"))) {
		status = "수료";
	} else if("F".equals(list2.s("complete_status"))) {
		status = "미수료";
	} else {
		status =
			!"".equals(list2.s("complete_date")) ? ( "Y".equals(list2.s("complete_yn")) ? _message.get("list.course_user.etc.complete_success") : _message.get("list.course_user.etc.complete_fail") )
			: ( !"Y".equals(list2.s("complete_auto_yn"))
				? _message.get("list.course_user.etc.inprogress")
				: _message.get("list.course_user.etc.complete_fail")
			)
		;
	}
	list2.put("status_conv", status);

	list2.put("mobile_block", list2.b("mobile_yn"));

	if(!"".equals(list2.s("course_file"))) {
		list2.put("course_file_url", m.getUploadUrl(list2.s("course_file")));
	} else {
		list2.put("course_file_url", "/html/images/common/noimage_course.gif");
	}

	list2.put("restudy_block", false);
	if(list2.b("restudy_yn")) {
		String edate = m.addDate("D", list2.i("restudy_day"), list2.s("end_date"), "yyyyMMdd");
		if(list2.b("restudy_yn") && 0 <= m.diffDate("D", today, edate)) {
			list2.put("restudy_block", true);
			isRestudy = true;
		}
	}
}

//출력
p.setLayout(ch);
p.setBody("mypage.course_list");
p.setVar("p_title", "수강현황");
p.setVar("form_script", f.getScript());

// 정규(학사) 과정과 비정규(LMS) 과정을 별도 리스트로 전달
p.setLoop("list1_haksa", list1_haksa);
p.setLoop("list1_prism", list1_prism);
p.setLoop("list2", list2);

// 학사 과정 존재 여부 (탭 표시용)
p.setVar("has_haksa", list1_haksa.size() > 0);
p.setVar("has_prism", list1_prism.size() > 0);

p.setVar("user", uinfo);
p.setVar("restudy_block", isRestudy);

p.display();


%>
