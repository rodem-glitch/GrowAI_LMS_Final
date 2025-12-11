<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String mode = m.rs("mode");
boolean managementBlock = "management".equals(mode);

//접근권한
if(!managementBlock) {
	//통합수강생관리
	if(!Menu.accessible(116, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }
} else {
	//과정운영
	if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }
}

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
LmCategoryDao category = new LmCategoryDao("course");
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();

CourseProgressDao courseProgress = new CourseProgressDao();
CourseUserLogDao courseUserLog = new CourseUserLogDao();
ExamUserDao examUser = new ExamUserDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();
ForumUserDao forumUser = new ForumUserDao();
SurveyUserDao surveyUser = new SurveyUserDao();

OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();

//삭제
if("del".equals(mode)) {
	//기본키
	int id = m.ri("id");
	if(id == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	//정보
	DataSet info = courseUser.find("id = " + id + " AND status != -1");
	if(!info.next()) { m.jsAlert("해당 정보가 없습니다."); return; }

	//제한
	if(0 < courseProgress.findCount("course_user_id = " + id + "")) {
		m.jsAlert("강의에 대한 진도내역이 있습니다. 삭제할 수 없습니다."); return;
	}
	if(0 < courseUserLog.findCount("course_user_id = " + id + "")) {
		m.jsAlert("학습내역이 있습니다. 삭제할 수 없습니다."); return;
	}
	if(0 < examUser.findCount("course_user_id = " + id + "")) {
		m.jsAlert("시험응시내역이 있습니다. 삭제할 수 없습니다."); return;
	}
	if(0 < homeworkUser.findCount("course_user_id = " + id + "")) {
		m.jsAlert("과제제출내역이 있습니다. 삭제할 수 없습니다."); return;
	}
	if(0 < forumUser.findCount("course_user_id = " + id + "")) {
		m.jsAlert("토론참여내역이 있습니다. 삭제할 수 없습니다."); return;
	}
	if(0 < surveyUser.findCount("course_user_id = " + id + "")) {
		m.jsAlert("설문참여내역이 있습니다. 삭제할 수 없습니다."); return;
	}

	//삭제
	if(!courseUser.delete("id = " + id + "")) { m.jsAlert("삭제하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsReplace("user_list.jsp?" + m.qs("id,mode"), "parent");
	return;
} else if("confirm".equals(mode)) {
	//기본키
	int cuid = m.ri("cuid");
	if(cuid == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	//정보
	DataSet cuinfo = courseUser.query(
		" SELECT a.order_item_id id, a.id course_user_id, a.site_id, a.user_id "
		+ " , c.course_type, c.lesson_day, c.study_sdate, c.study_edate "
		+ " FROM " + courseUser.table + " a "
		+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
		+ " WHERE a.id = " + cuid + " AND a.status = 0 AND a.site_id = " + siteId
	);
	if(!cuinfo.next()) { m.jsAlert("해당 정보가 없습니다."); return; }

	if(!courseUser.updateStudyDate(cuinfo, 1, "F")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsAlert("수강승인이 완료됐습니다.");
	m.jsReplace("user_list.jsp?" + m.qs("mode,cuid"), "parent");
	return;
} else if("deposit".equals(mode)) {
	//기본키
	String oid = m.rs("oid");
	if("".equals(oid)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	if(!order.confirmDeposit(oid, siteinfo)) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsAlert("입금확인이 완료됐습니다.");
	m.jsReplace("user_list.jsp?" + m.qs("mode,oid"), "parent");
	return;
}

//처리
if(m.isPost()) {

	String[] idx = f.getArr("idx");
	if(idx.length == 0) { m.jsError("선택한 회원이 없습니다."); return; }

	if(-1 == courseUser.execute(
		"UPDATE " + courseUser.table + " SET "
		+ " status = " + f.get("a_status") + " "
		+ ", change_date = '" + m.time("yyyyMMddHHmmss") + "' "
		+ " WHERE id IN (" + m.join(",", idx) + ") "
	)) {
		m.jsError("변경처리하는 중 오류가 발생했습니다."); return;
	}

	m.jsReplace("user_list.jsp?" + m.qs("idx"));
	return;
}

//정보
DataSet cinfo = new DataSet();
if(managementBlock) {
	cinfo = course.find(
		"id = " + f.get("s_course_id") + " AND site_id = " + siteId + " AND status != -1"
		+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
	);
	if(!cinfo.next()) { m.jsAlert("해당 과정정보가 없습니다."); return; }
}

//폼체크
f.addElement("s_course_id", null, null);
if(!managementBlock) {
	f.addElement("s_category", null, null);
	f.addElement("s_onofftype", null, null);
	f.addElement("s_type", null, null);
}
f.addElement("s_reg_sdate", null, null);
f.addElement("s_reg_edate", null, null);
f.addElement("s_start_date", null, null);
f.addElement("s_end_date", null, null);
f.addElement("s_dept", null, null);
f.addElement("s_complete", null, null);
f.addElement("s_complete_sdate", null, null);
f.addElement("s_complete_edate", null, null);
f.addElement("s_status", null, null);
f.addElement("s_out_yn", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//카테고리
DataSet categories = category.getList(siteId);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(("excel".equals(mode) || "uidx".equals(mode)) ? 20000 : f.getInt("s_listnum", 20));
lm.setTable(
	courseUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id " + (!"Y".equals(f.get("s_out_yn")) ? " AND u.status != -1 " : "")
	+ " LEFT JOIN " + course.table + " c ON a.course_id = c.id "
	//+ " LEFT JOIN " + order.table + " o ON a.order_id = o.id "
	//+ " LEFT JOIN " + orderItem.table + " oi ON a.order_item_id = oi.id "
);
lm.setFields(
	"a.*, u.user_nm, u.login_id "
	+ ("excel".equals(mode) ? ", u.dept_id, u.email, u.zipcode, u.addr, u.new_addr, u.addr_dtl, u.gender, u.birthday, u.mobile, u.etc1, u.etc2, u.etc3, u.etc4, u.etc5, u.email_yn, u.sms_yn" : "")
	+ ", c.category_id, c.onoff_type, c.course_nm, c.credit, c.lesson_time, c.cert_complete_yn " //, o.paymethod, oi.price, oi.pay_price"
);
lm.addWhere("a.site_id = " + siteId + " AND a.status != -1");
//lm.addWhere("u.site_id = " + siteId);
//lm.addWhere("a.course_id = " + courseId + "");
lm.addSearch("a.course_id", f.get("s_course_id"));
if(deptManagerBlock) lm.addWhere("u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ")");
if(!managementBlock) {
	if(!"".equals(f.get("s_category"))) lm.addWhere("c.category_id IN ( '" + m.join("','", category.getChildNodes(f.get("s_category"))) + "' )");
	lm.addSearch("c.onoff_type", f.get("s_onofftype"));
	lm.addSearch("c.course_type", f.get("s_type"));
}
if(courseManagerBlock) lm.addWhere("a.course_id IN (" + manageCourses + ")");
if(0 < f.getInt("s_dept")) lm.addWhere("u.dept_id IN (" + userDept.getSubIdx(siteId, f.getInt("s_dept")) + ")");
lm.addSearch("a.complete_yn", f.get("s_complete"));
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_reg_sdate"))) lm.addWhere("a.reg_date >= '" + m.time("yyyyMMdd000000", f.get("s_reg_sdate")) + "'");
if(!"".equals(f.get("s_reg_edate"))) lm.addWhere("a.reg_date <= '" + m.time("yyyyMMdd235959", f.get("s_reg_edate")) + "'");
if(!"".equals(f.get("s_start_date"))) lm.addWhere("a.end_date >= '" + m.time("yyyyMMdd", f.get("s_start_date")) + "'");
if(!"".equals(f.get("s_end_date"))) lm.addWhere("a.start_date <= '" + m.time("yyyyMMdd", f.get("s_end_date")) + "'");
if(!"".equals(f.get("s_complete_sdate"))) lm.addWhere("a.complete_date >= '" + m.time("yyyyMMdd000000", f.get("s_complete_sdate")) + "'");
if(!"".equals(f.get("s_complete_edate"))) lm.addWhere("a.complete_date <= '" + m.time("yyyyMMdd235959", f.get("s_complete_edate")) + "'");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.id, a.order_id, a.order_item_id, u.user_nm, u.login_id, u.etc1, u.etc2, u.etc3, u.etc4, u.etc5", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
if(!"uidx".equals(mode)) {
	//일반
	while(list.next()) {
		if(0 < list.i("dept_id")) {
			list.put("dept_nm_conv", userDept.getNames(list.i("dept_id")));
		} else {
			list.put("dept_nm", "[미소속]");
			list.put("dept_nm_conv", "[미소속]");
		}

		list.put("price", 0);
		list.put("pay_price", 0);
		list.put("order_id", 0);
		list.put("paymethod", "");
		list.put("paymethod_conv", "");
		if(0 < list.i("order_item_id")) {
			DataSet oinfo = order.query(
				" SELECT a.price, a.pay_price, o.id order_id, o.paymethod "
				+ " FROM " + orderItem.table + " a "
				+ " LEFT JOIN " + order.table + " o ON a.order_id = o.id "
				+ " WHERE a.id = " + list.i("order_item_id") + " AND a.status != -1 "
			);
			if(oinfo.next()) {
				list.put("price", oinfo.i("price"));
				list.put("pay_price", oinfo.i("pay_price"));
				list.put("order_id", oinfo.i("order_id"));
				list.put("paymethod", oinfo.i("paymethod"));
				list.put("paymethod_conv", m.getItem(oinfo.i("paymethod"), order.methods));
			}
		}

		list.put("email_yn_conv", m.getItem(list.s("email_yn"), user.receiveYn));
		list.put("sms_yn_conv", m.getItem(list.s("sms_yn"), user.receiveYn));

		list.put("category_nm_conv", category.getTreeNames(list.i("category_id")));
		list.put("course_nm_conv", m.cutString(list.s("course_nm"), 34));
		list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffTypes));
		list.put("start_date_conv", m.time("yyyy.MM.dd", list.s("start_date")));
		list.put("end_date_conv", m.time("yyyy.MM.dd", list.s("end_date")));
		list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
		list.put("complete_date_conv", m.time("yyyy.MM.dd", list.s("complete_date")));
		list.put("status_conv", m.getItem(list.s("status"), courseUser.statusList));

		list.put("progress_ratio_conv", m.nf(list.d("progress_ratio"), 1));
		list.put("total_score_conv", m.nf(list.d("total_score"), 2));

		list.put("birthday_conv", m.time("yyyy.MM.dd", list.s("birthday")));
		list.put("mobile_conv", "-");
		list.put("mobile_conv", !"".equals(list.s("mobile")) ? list.s("mobile") : "-" );
		list.put("gender_conv", m.getItem(list.s("gender"), user.genders));

		list.put("deposit_block", "90".equals(list.s("paymethod")) && 2 == list.i("status"));
		list.put("confirm_block", 0 == list.i("status"));
		list.put("important_block", list.b("deposit_block") || list.b("confirm_block"));
		list.put("order_block", 0 < list.i("order_id"));

		list.put("pay_price_conv", m.nf(list.i("pay_price")));
		
		list.put("complete_yn_conv", m.getItem(list.s("complete_yn"), courseUser.completeYn));
		list.put("complete_no_conv", "Y".equals(list.s("complete_yn")) ? list.s("complete_no") : "");

		list.put("ROW_CLASS", list.b("important_block") ? "important" : list.s("ROW_CLASS"));

		user.maskInfo(list);
	}
} else {
	//회원번호추출
	ArrayList<Integer> uidx = new ArrayList<Integer>();
	while(list.next()) {
		if(!uidx.contains(list.i("user_id"))) uidx.add(list.i("user_id"));
	}
	out.print(m.join(",", uidx.toArray()));
	return;
}

//기록-개인정보조회
if(list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), inquiryPurpose, list);

//엑셀
if("excel".equals(mode)) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), inquiryPurpose, list);

	ExcelWriter ex = new ExcelWriter(response, "수강생관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>수강생ID", "user_nm=>수강생명", "dept_nm_conv=>회원소속", "user_id=>회원번호", "login_id=>로그인아이디", "onoff_type_conv=>과정구분", "category_nm_conv=>과정카테고리명", "course_id=>과정ID", "course_nm=>과정명", "credit=>학점", "lesson_time=>시수", "progress_ratio=>진도율", "progress_score=>진도점수", "exam_value=>시험점수(100점환산)", "exam_score=>시험점수", "homework_value=>과제점수(100점환산)", "homework_score=>과제점수", "forum_value=>토론점수(100점환산)", "forum_score=>토론점수", "etc_value=>기타점수(100점환산)", "etc_score=>기타점수", "total_score=>총점", "start_date_conv=>학습시작일", "end_date_conv=>학습종료일", "price=>과정정가", "order_id=>주문번호", "pay_price=>결제금액", "paymethod_conv=>결제수단", "reg_date_conv=>등록일", "complete_yn_conv=>수료여부", "complete_date_conv=>수료판정일", "complete_no_conv=>수료번호", "status_conv=>상태", "gender_conv=>성별", "birthday_conv=>생년월일", "email=>이메일", "zipcode=>우편번호", "new_addr=>주소", "addr_dtl=>상세주소", "mobile_conv=>휴대전화", "etc1=>" + SiteConfig.s("user_etc_nm1"), "etc2=>" + SiteConfig.s("user_etc_nm2"), "etc3=>" + SiteConfig.s("user_etc_nm3"), "etc4=>" + SiteConfig.s("user_etc_nm4"), "etc5=>" + SiteConfig.s("user_etc_nm5"), "email_yn_conv=>이메일수신동의여부", "sms_yn_conv=>SMS수신동의여부" }, "수강생관리(" + m.time("yyyy-MM-dd") +")");
	ex.write();
	return;
}

//출력
p.setLayout("sysop");
p.setBody("course.user_list");
p.setVar("p_title"
	, !managementBlock
	? "통합수강생관리"
	: "<span style='color:#666666'>[" + cinfo.s("year") + "년/" + cinfo.s("step") + "기]</span> <span style='color:#4C5BA9'>" + cinfo.s("course_nm") + "</span>"
);
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("mode_query", m.qs("mode"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("SITE_CONFIG", SiteConfig.getArr("user_etc_"));
p.setLoop("categories", categories);
p.setLoop("dept_list", userDept.getList(siteId, userKind, userDeptId));
p.setLoop("courses", course.getCourseList(siteId, userId, userKind));
p.setLoop("types", m.arr2loop(course.types));
p.setLoop("onoff_types", m.arr2loop(course.onoffTypes));
p.setLoop("status_list", m.arr2loop(courseUser.statusList));
p.setVar("template_block", 0 < cinfo.i("cert_template_id"));
p.setVar("management_block", managementBlock);
p.setVar("alltime_block", "A".equals(cinfo.s("course_type")));
p.display();

%>