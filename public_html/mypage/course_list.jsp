<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CourseUserDao courseUser = new CourseUserDao();
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");

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

//수강중인 과정
DataSet list1 = courseUser.query(
	" SELECT a.*, c.year, c.step, c.course_nm, c.course_type, c.onoff_type, c.course_file, c.credit, c.lesson_time, c.renew_max_cnt, c.renew_yn, c.mobile_yn, ct.category_nm "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " LEFT JOIN " + category.table + " ct ON c.category_id = ct.id AND ct.module = 'course' AND ct.status = 1 "
	+ " WHERE a.user_id = " + userId + " AND a.status IN (0, 1, 3) "
	+ (!"".equals(type) ? " AND c.onoff_type " + ("on".equals(type) ? "=" : "!=") + " 'N' " : "")
	+ " AND a.close_yn = 'N' AND a.end_date >= '" + today + "' "
	+ " ORDER BY " + ord + ", a.id DESC "
);
while(list1.next()) {
	list1.put("start_date_conv", m.time(_message.get("format.date.dot"), list1.s("start_date")));
	list1.put("end_date_conv", m.time(_message.get("format.date.dot"), list1.s("end_date")));
	list1.put("study_date_conv", list1.s("start_date_conv") + " - " + list1.s("end_date_conv"));
	list1.put("course_nm_conv", m.cutString(list1.s("course_nm"), 40));
	list1.put("progress_ratio", m.nf(list1.d("progress_ratio"), 1).replace(".0", ""));
	list1.put("total_score", m.nf(list1.d("total_score"), 1).replace(".0", ""));
	list1.put("type_conv", m.getValue(list1.s("course_type"), course.typesMsg));
	list1.put("onoff_type_conv", m.getValue(list1.s("onoff_type"), course.onoffTypesMsg));
	list1.put("credit", list1.i("credit"));
	list1.put("mobile_block", list1.b("mobile_yn"));

	list1.put("renew_block", courseUser.setRenewBlock(list1.getRow()));

	if(!"".equals(list1.s("course_file"))) {
		list1.put("course_file_url", m.getUploadUrl(list1.s("course_file")));
	} else {
		list1.put("course_file_url", "/html/images/common/noimage_course.gif");
	}

	String status = "";
	boolean isOpen = false;
	boolean isCancel = false;
	if(list1.i("status") == 0) {
		status = _message.get("list.course_user.etc.waiting_approve");
		if(0 == list1.i("order_id")) isCancel = true;
	} else if(0 > m.diffDate("D", list1.s("start_date"), today)) {
		status = _message.get("list.course_user.etc.waiting_learning");
		//if(0 == list1.i("order_id")) isCancel = true;
		isCancel = true;
	} else {
		if(list1.b("complete_yn")) {
			status = _message.get("list.course_user.etc.complete_success");
		} else {
			status = _message.get("list.course_user.etc.learning");
			//if(0 == list1.i("order_id") && "A".equals(list1.s("course_type"))) isCancel = true;
			if(0 == list1.i("order_id")) isCancel = true;
		}
		isOpen = true;
	}

	list1.put("status_conv", status);
	list1.put("open_block", isOpen);
	list1.put("cancel_block", isCancel);
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
	//list2.put("status_conv", list2.b("complete_yn") ? "수료" : "미수료");
	list2.put("status_conv",
		!"".equals(list2.s("complete_date")) ? ( "Y".equals(list2.s("complete_yn")) ? _message.get("list.course_user.etc.complete_success") : _message.get("list.course_user.etc.complete_fail") )
		: ( !"Y".equals(list2.s("complete_auto_yn"))
			? _message.get("list.course_user.etc.inprogress")
			: _message.get("list.course_user.etc.complete_fail")
		)
	);

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

p.setLoop("list1", list1);
p.setLoop("list2", list2);

p.setVar("user", uinfo);
p.setVar("restudy_block", isRestudy);

p.display();

%>