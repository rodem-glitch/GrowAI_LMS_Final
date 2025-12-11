<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int hid = m.ri("hid");
if(hid == 0 || courseId == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

String submitYn = m.rs("s_submit_yn", "Y");
if("".equals(submitYn)) submitYn = "Y";

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
HomeworkDao homework = new HomeworkDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();
ClFileDao file = new ClFileDao();

//정보
DataSet info = courseModule.query(
	"SELECT a.course_id, a.apply_type, a.start_date, a.end_date, a.chapter, a.assign_score "
	+ ", h.* "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + homework.table + " h ON a.module_id = h.id "
	+ " WHERE a.status = 1 AND a.module = 'homework' "
	+ " AND a.module_id = " + hid + " AND a.course_id = " + courseId + " "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }


//처리
if("cancel".equals(m.rs("mode"))) {

	//기본키
	int cuid = m.ri("cuid");
	if(cuid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	//정보-응시자정보
	DataSet euinfo = homeworkUser.find("homework_id = " + hid + " AND course_user_id = " + cuid + "");
	if(!euinfo.next()) { m.jsError("해당 제출 정보가 없습니다."); return; }

	//삭제
	if(!homeworkUser.delete("homework_id = " + hid + " AND course_user_id = " + cuid + "")) {
		m.jsError("제출 취소하는 중 오류가 발생했습니다."); return;
	}

	//점수 업데이트
	courseUser.setCourseUserScore(cuid, "homework");

	m.jsAlert("제출취소 되었습니다.");
	m.jsReplace("homework_user.jsp?" + m.qs("mode,hu_idx,cuid"), "parent");
	return;
}

//처리
if(m.isPost()) {
	//제출
	if("mark".equals(f.get("mode"))) {
		String idx = f.get("hu_idx");
		if("".equals(idx)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

		if(-1 == homeworkUser.execute(
			"UPDATE " + homeworkUser.table + " "
			+ " SET submit_yn = 'Y' "
			+ " WHERE course_user_id IN (" + idx + ") "
			+ " AND course_id = " + courseId + " AND homework_id = " + hid + " "
			+ " AND status = 1 "
		)) {
			m.jsError("제출 처리하는 중 오류가 발생했습니다."); return;
		}
	} else if("mod".equals(f.get("mode"))) {
		//기본키
		int cuid = f.getInt("cuid");
		int score = f.getInt("score");
		if(cuid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

		//총점 저장
		if(-1 == homeworkUser.execute(
			"UPDATE " + homeworkUser.table + " "
			+ " SET confirm_yn = 'Y' "
			+ ", score = " + Math.min(info.d("assign_score"), info.d("assign_score") * score / 100) + " "
			+ ", marking_score = " + Math.min(score, 100.0) + " "
			+ ", confirm_user_id = " + userId + " "
			+ ", confirm_date = '" + m.time("yyyyMMddHHmmss") + "' "
			+ " WHERE homework_id = " + hid + " AND course_user_id = " + cuid + " "
		)) {
			m.jsError("평가하는 중 오류가 발생했습니다."); return;
		}

		//점수 업데이트
		courseUser.setCourseUserScore(cuid, "homework");

		m.jsAlert("수정되었습니다.");
	}

	m.jsReplace("homework_user.jsp?" + m.qs("mode,hu_idx,cuid"), "parent");
	return;
}

//폼체크
f.addElement("s_submit_yn", submitYn, null);
f.addElement("s_confirm_yn", null, null);
f.addElement("s_out_yn", null, null);
f.addElement("s_delete_yn", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) || "download".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(
	courseUser.table + " a "
	+ " LEFT JOIN " + homeworkUser.table + " b ON b.course_user_id = a.id AND b.homework_id = " + hid + " AND b.status = 1 "
	+ " INNER JOIN " + user.table + " c ON a.user_id = c.id " + (!"Y".equals(f.get("s_out_yn")) ? " AND c.status != -1 " : "")
			+ (deptManagerBlock ? " AND c.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
);
lm.setFields(
	"a.id, a.user_id u_id "
	+ ", b.* "
	+ ", c.user_nm, c.login_id "
	+ ", (SELECT GROUP_CONCAT(filename) FROM " + file.table + " WHERE module = 'homework_" + hid + "' AND module_id = a.id) as user_file "
);
if(!"Y".equals(f.get("s_delete_yn"))) lm.addWhere("a.status IN (1,3)");
lm.addWhere("a.course_id = " + courseId + "");
lm.addWhere(
	(!"Y".equals(submitYn) ? "NOT" : "")
	+ " EXISTS ( "
		+ " SELECT 1 FROM " + homeworkUser.table + " "
		+ " WHERE course_user_id = a.id AND homework_id = " + hid + " AND status = 1 "
	+ ")"
);
if("Y".equals(submitYn)) lm.addSearch("b.confirm_yn", f.get("s_confirm_yn"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("b.subject,c.login_id,c.user_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy("a.id DESC, c.user_nm ASC");

//목록
int fcnt = 0;
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", !"".equals(list.s("reg_date")) ? m.time("yyyy.MM.dd HH:mm", list.s("reg_date")) : "-");
	list.put("confirm_conv", "Y".equals(list.s("confirm_yn")) ? "평가완료" : "미평가");
	list.put("marking_score_conv", m.nf(list.d("marking_score"), 0));
	double score = Math.min(info.d("assign_score"), info.d("assign_score") * list.d("marking_score") / 100);
	list.put("score_conv", m.nf(score, 2));
	if(!"".equals(list.s("user_file"))) fcnt++;
	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

//모두내려받기
int bFile = 0;
if("download".equals(m.rs("mode"))) {
	if(fcnt == 0) { m.jsError("첨부파일이 없습니다."); return; }
	list.first();
	String[] pathList = new String[fcnt];
	int j = 0;
	for(int i = 0; list.next(); i++) {
		if(!"".equals(list.s("user_file"))) pathList[j++] = m.getUploadPath(list.s("user_file")) + "=>" + list.s("user_nm") + "(" + list.s("login_id") + ")_" + list.s("user_file");
	}

	Zip zip = new Zip();
	zip.compress(pathList, "[" + info.s("year") + "_" + info.s("step") + "_" + info.s("course_nm") + "]" + info.s("module_nm") + ".zip", response);
	return;
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), "이러닝 운영", list);

	ExcelWriter ex = new ExcelWriter(response, "[" + info.s("year") + "_" + info.s("step") + "_" + info.s("course_nm") + "]" + info.s("module_nm") + "_과제제출자현황.xls");
	ex.setData(list, new String[] { "__ord=>No", "user_nm=>이름", "u_id=>회원ID", "login_id=>로그인ID", "subject=>제목", "user_file=>첨부파일", "reg_date=>제출일", "confirm_str=>채점여부", "marking_score_conv=>채점점수", "score_conv=>환산점수" }, "[" + info.s("year") + "_" + info.s("step") + "_" + info.s("course_nm") + "] " + info.s("module_nm") + "_과제제출자현황");
	ex.write();
	return;
}

//출력
p.setLayout("blank");
p.setBody("management.homework_user");
p.setVar("query", m.qs("mode"));
p.setVar("list_query", m.qs("mode,eu_idx,cuid"));
p.setVar("form_script", f.getScript());

p.setVar("homework", info);

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("confirm_block", "Y".equals(submitYn));
p.setVar("offline_block", "F".equals(info.s("onoff_type")));
p.setVar("mod_block",  "Y".equals(submitYn) && "F".equals(info.s("onoff_type")));
p.display();

%>