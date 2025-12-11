<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int eid = m.ri("eid");
if(eid == 0 || courseId == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

String submitYn = m.rs("s_submit_yn", "Y");
if("".equals(submitYn)) submitYn = "Y";

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
ExamDao exam = new ExamDao();
ExamUserDao examUser = new ExamUserDao();
ExamResultDao examResult = new ExamResultDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

//정보
DataSet info = courseModule.query(
	"SELECT a.course_id, a.apply_type, a.start_date, a.end_date, a.chapter, a.assign_score "
	+ ", e.* "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + exam.table + " e ON a.module_id = e.id "
	+ " WHERE a.status = 1 AND a.module = 'exam' "
	+ " AND a.course_id = " + courseId + " AND a.module_id = " + eid + ""
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//응시취소 처리
if("cancel".equals(m.rs("mode"))) {

	//기본키
	int cuid = m.ri("cuid");
	if(cuid == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	//정보-응시자정보
	DataSet euinfo = examUser.find("exam_id = " + eid + " AND course_user_id = " + cuid + "");
	if(!euinfo.next()) { m.jsAlert("해당 응시 정보가 없습니다."); return; }

	//삭제-결과
	if(!examResult.delete("exam_id = " + eid + " AND course_user_id = " + cuid + "")) {
		m.jsAlert("응시 취소하는 중 오류가 발생했습니다."); return;
	}

	//삭제
	if(!examUser.delete("exam_id = " + eid + " AND course_user_id = " + cuid + "")) {
		m.jsAlert("응시 취소하는 중 오류가 발생했습니다."); return;
	}

	//점수 업데이트
	courseUser.setCourseUserScore(cuid, "exam");

	m.jsAlert("응시취소 되었습니다.");
	m.jsReplace("exam_user.jsp?" + m.qs("mode,eu_idx,cuid"), "parent");
	return;
}

//처리
if(m.isPost()) {
	//제출
	if("mark".equals(f.get("mode"))) {
		String idx = f.get("eu_idx");
		if("".equals(idx)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

		if(-1 == examUser.execute(
			"UPDATE " + examUser.table + " "
			+ " SET submit_yn = 'Y' "
			+ " WHERE course_user_id IN (" + idx + ") "
			+ " AND course_id = " + courseId + " AND exam_id = " + eid + " "
			+ " AND status = 1 "
		)) {
			m.jsAlert("제출 처리하는 중 오류가 발생했습니다."); return;
		}
	} else if("mod".equals(f.get("mode"))) {
		//기본키
		int cuid = f.getInt("cuid");
		int score = f.getInt("score");
		if(cuid == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

		//총점 저장
		if(-1 == examUser.execute(
			"UPDATE " + examUser.table + " "
			+ " SET confirm_yn = 'Y' "
			+ ", score = " + Math.min(info.d("assign_score"), info.d("assign_score") * score / 100) + " "
			+ ", marking_score = " + Math.min(score, 100.0) + " "
			+ ", confirm_user_id = " + userId + " "
			+ ", confirm_date = '" + m.time("yyyyMMddHHmmss") + "' "
			+ " WHERE exam_id = " + eid + " AND course_user_id = " + cuid + " "
		)) {
			m.jsAlert("평가하는 중 오류가 발생했습니다."); return;
		}

		//점수 업데이트
		courseUser.setCourseUserScore(cuid, "exam");

		m.jsAlert("수정되었습니다.");
	}

	m.jsReplace("exam_user.jsp?" + m.qs("mode,eu_idx,cuid"), "parent");
	return;
}


//폼체크
f.addElement("s_submit_yn", submitYn, null);
f.addElement("s_confirm_yn", null, null);
f.addElement("s_out_yn", null, null);
f.addElement("s_delete_yn", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) || "download".equals(m.rs("mode")) ? 20000 : f.getInt("s_listnum", 20));
lm.setTable(
	courseUser.table + " a "
	+ " LEFT JOIN " + examUser.table + " b ON b.course_user_id = a.id AND b.exam_id = " + eid + " AND b.status = 1 "
	+ " INNER JOIN " + user.table + " c ON c.id = a.user_id " + (!"Y".equals(f.get("s_out_yn")) ? " AND c.status != -1 " : "")
		+ (deptManagerBlock ? " AND c.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
);
lm.setFields(
	"a.id, a.user_id u_id "
	+ ", b.* "
	+ ", c.user_nm, c.login_id "
);
if(!"Y".equals(f.get("s_delete_yn"))) lm.addWhere("a.status IN (1,3)");
lm.addWhere("a.course_id = " + courseId + "");
lm.addWhere(
	( "F".equals(submitYn) ? "NOT" : "")
	+ " EXISTS ( "
		+ " SELECT 1 FROM " + examUser.table + " "
		+ " WHERE course_user_id = a.id AND exam_id = " + eid + " AND status = 1 "
	+ " )"
);
if(!"F".equals(submitYn)) {
	lm.addWhere("b.submit_yn = '" + submitYn + "'");
	lm.addSearch("b.confirm_yn", f.get("s_confirm_yn"));
}
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("c.login_id,c.user_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC, c.user_nm ASC, a.id ASC");

DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("confirm_date_conv", !"".equals(list.s("confirm_date")) ? m.time("yyyy.MM.dd HH:mm:ss", list.s("confirm_date")) : "-");
	list.put("submit_date_conv", !"".equals(list.s("submit_date")) ? m.time("yyyy.MM.dd HH:mm:ss", list.s("submit_date")) : "-");
	list.put("apply_date_conv", !"".equals(list.s("apply_date")) ? m.time("yyyy.MM.dd HH:mm:ss", list.s("apply_date")) : "-");
	list.put("onload_date_conv", !"".equals(list.s("onload_date")) ? m.time("yyyy.MM.dd HH:mm:ss", list.s("onload_date")) : "-");
	list.put("unload_date_conv", !"".equals(list.s("unload_date")) ? m.time("yyyy.MM.dd HH:mm:ss", list.s("unload_date")) : "-");
	list.put("reg_date_conv", !"".equals(list.s("reg_date")) ? m.time("yyyy.MM.dd HH:mm:ss", list.s("reg_date")) : "-");
	list.put("confirm_conv", "Y".equals(list.s("confirm_yn")) ? "평가완료" : "미평가");
	list.put("marking_score_conv", m.nf(list.d("marking_score"), 0));
	double score = Math.min(info.d("assign_score"), info.d("assign_score") * list.d("marking_score") / 100);
	list.put("score_conv", m.nf(score, 2));
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), inquiryPurpose, list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), "이러닝 운영", list);

	ExcelWriter ex = new ExcelWriter(response, "[" + cinfo.s("year") + "_" + cinfo.s("step") + "_" + cinfo.s("course_nm") + "]" + info.s("exam_nm") + "_평가응시자현황.xls");
	ex.setData(list, new String[] { "__ord=>No", "user_nm=>이름", "u_id=>회원ID", "login_id=>로그인ID", "confirm_date_conv=>평가일시", "submit_date_conv=>제출일시", "apply_date_conv=>최초응시일시", "onload_date_conv=>최종페이지로드일시", "unload_date_conv=>최후페이지종료일시", "ip_addr=>아이피주소", "reg_date_conv=>응시일시", "confirm_yn=>평가여부", "marking_score_conv=>취득점수", "score_conv=>환산점수" }, "[" + info.s("year") + "_" + cinfo.s("step") + "_" + cinfo.s("course_nm") + "] " + info.s("exam_nm") + "_평가응시자현황");
	ex.write();
	return;
}

//출력
p.setLayout("blank");
p.setBody("management.exam_user");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("mode,eu_idx,cuid"));
p.setVar("form_script", f.getScript());

p.setVar("exam", info);

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("dis_block", "N".equals(submitYn));
p.setVar("confirm_block", "Y".equals(submitYn));
p.setVar("delete_block", !"F".equals(submitYn));
p.setVar("offline_block", "F".equals(info.s("onoff_type")));
p.setVar("mod_block",  "Y".equals(submitYn) && "F".equals(info.s("onoff_type")));

p.display();

%>