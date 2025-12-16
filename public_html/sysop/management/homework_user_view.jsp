<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int hid = m.ri("hid");
int cuid = m.ri("cuid");
if(hid == 0 || cuid == 0 || courseId == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();
HomeworkTaskDao homeworkTask = new HomeworkTaskDao();
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();
ClFileDao file = new ClFileDao();

//정보-모듈
DataSet minfo = courseModule.find("status = 1 AND module = 'homework' AND module_id = " + hid + " AND course_id = " + courseId + "");
if(!minfo.next()) { m.jsError("해당 평가 정보가 없습니다."); return; }

//정보
DataSet info = homeworkUser.query(
	"SELECT a.*, c.user_nm, c.login_id "
	+ " FROM " + homeworkUser.table + " a "
	+ " INNER JOIN " + courseUser.table + " b ON a.course_user_id = b.id AND b.status IN (1,3) "
	+ " INNER JOIN " + user.table + " c ON a.user_id = c.id " + (deptManagerBlock ? " AND c.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE a.course_user_id = " + cuid + " AND a.homework_id = " + hid + " AND b.course_id = " + courseId + " AND a.status = 1 "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
user.maskInfo(info);

//기록-개인정보조회
if("".equals(m.rs("mode")) && info.size() > 0 && !isBlindUser) _log.add("V", Menu.menuNm, info.size(), "이러닝 운영", info);

//삭제
if("del".equals(m.rs("mode"))) {
	if(m.encrypt("del" + userId).equals(m.rs("dek"))) {
		homeworkUser.item("score",  0);
		homeworkUser.item("marking_score",  0);
		homeworkUser.item("feedback", "");
		homeworkUser.item("confirm_yn", "N");
		homeworkUser.item("confirm_user_id", userId);
		homeworkUser.item("confirm_date", "");

		if(!homeworkUser.update("homework_id = " + hid + " AND course_user_id = " + cuid + "")) {
			m.jsError("저장하는 중 오류가 발생했습니다."); return;
		}

		//점수 업데이트
		courseUser.setCourseUserScore(cuid, "homework");

		m.jsAlert("삭제하였습니다.");
		m.js("opener.location.href = opener.location.href; window.close();");
		return;
	} else {
		m.jsError("올바른 접근이 아닙니다.");
		return;
	}
}

//폼체크
f.addElement("score", info.s("marking_score"), "hname:'점수', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");

//저장
if(m.isPost() && f.validate()) {

	String feedback = f.get("feedback");
	//제한-이미지URI
	if(-1 < feedback.indexOf("<img") && -1 < feedback.indexOf("data:image/") && -1 < feedback.indexOf("base64")) {
		m.jsAlert("이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}

	//제한-용량
	int bytes = feedback.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(60000 < bytes) {
		m.jsAlert("내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes + "바이트)");
		return;
	}

	homeworkUser.item("score", Math.min(minfo.d("assign_score"), minfo.d("assign_score") * m.parseDouble(f.get("score")) / 100));
	homeworkUser.item("marking_score", Math.min(m.parseDouble(f.get("score")), 100.0));
	homeworkUser.item("feedback", feedback);
	homeworkUser.item("confirm_yn", "Y");
	homeworkUser.item("confirm_date", m.time("yyyyMMddHHmmss"));
	homeworkUser.item("confirm_user_id", userId);

	if(!homeworkUser.update("homework_id = " + hid + " AND course_user_id = " + cuid + "")) {
		m.jsError("저장하는 중 오류가 발생했습니다."); return;
	}

	//점수 업데이트
	courseUser.setCourseUserScore(cuid, "homework");

	m.jsAlert("수정하였습니다.");
	m.js("opener.location.href = opener.location.href; window.close();");
	return;
}

info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", (!"".equals(info.s("mod_date")) ? info.s("mod_date") : info.s("reg_date"))));
info.put("confirm_str", "Y".equals(info.s("confirm_yn")) ? "평가완료" : "미평가");
/*
info.put("user_file_conv", m.encode(info.s("user_file")));
info.put("user_file_url", m.getUploadPath(info.s("user_file")));
info.put("user_file_ek", m.encrypt(info.s("user_file") + m.time("yyyyMMdd")));
*/
info.put("confirm_block", "Y".equals(info.s("confirm_yn")));

//추가과제 목록
//왜: LM_HOMEWORK_USER는 1회 제출/피드백만 저장되므로, 반복되는 추가 과제를 별도 테이블에서 조회합니다.
DataSet taskList = homeworkTask.find(
	"site_id = " + siteId + " AND course_id = " + courseId + " AND homework_id = " + hid + " AND course_user_id = " + cuid + " AND status = 1"
	, "*"
	, "id ASC"
);
while(taskList.next()) {
	taskList.put("reg_date_conv", !"".equals(taskList.s("reg_date")) ? m.time("yyyy.MM.dd HH:mm", taskList.s("reg_date")) : "-");
	taskList.put("submit_conv", "Y".equals(taskList.s("submit_yn")) ? "제출" : "미제출");
	taskList.put("confirm_conv", "Y".equals(taskList.s("confirm_yn")) ? "피드백완료" : "미피드백");
}

//목록-파일
DataSet files = file.find("module = 'homework_" + hid + "' AND module_id = " + cuid + " AND status = 1");
while(files.next()) {
	//files.put("ek", m.encrypt(files.s("id")));
	//files.put("filename_conv", m.urlencode(Base64Coder.encode(files.s("filename"))));
	
	files.put("ext", file.getFileIcon(files.s("filename")));
	files.put("ek", m.encrypt(files.s("filename") + m.time("yyyyMMdd")));
	files.put("filename_conv", m.encode(files.s("filename")));
}

//이전다음글
Vector<String> cond = new Vector<String>();
String submitYn = m.rs("s_submit_yn", "Y");
if("".equals(submitYn)) submitYn = "Y";
if(!"".equals(m.rs("s_keyword"))) {
	if("".equals(m.rs("s_field"))) {
		cond.add("( "
			+ " a.user_id LIKE '%" +  m.rs("s_keyword") + "%' "
			+ " OR b.subject LIKE '%" +  m.rs("s_keyword") + "%' "
			+ " OR c.user_nm LIKE '%" +  m.rs("s_keyword") + "%' "
		+ " )");
	} else {
		cond.add(m.rs("s_field") + " LIKE '%" +  m.rs("s_keyword") + "%'");
	}
}
if("Y".equals(submitYn) && !"".equals(m.rs("s_confirm_yn"))) cond.add("b.confirm_yn = '" + m.rs("s_confirm_yn") + "'");

DataSet prev = homeworkUser.query(
	"SELECT a.id cuid, a.user_id u_id "
	+ ", b.*"
	+ ", c.user_nm, c.login_id "
	+ ", (SELECT GROUP_CONCAT(filename) FROM " + file.table + " WHERE module = 'homework_" + hid + "' AND module_id = a.id) as user_file "
	+ " FROM " + courseUser.table + " a"
	+ " LEFT JOIN " + homeworkUser.table + " b ON b.course_user_id = a.id AND b.homework_id = " + hid + " AND b.status = 1"
	+ " INNER JOIN " + user.table + " c ON a.user_id = c.id " + (deptManagerBlock ? " AND c.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE a.id > " + cuid + " "
	+ " AND a.status IN (1,3) AND a.course_id = " + courseId + " "
	+ " AND " + (!"Y".equals(submitYn) ? "NOT" : "") + " EXISTS (SELECT 1 FROM " + homeworkUser.table + " WHERE course_user_id = a.id AND homework_id = " + hid + " AND status = 1)"
	+ (cond.isEmpty() ? "" : " AND " + (m.join(" AND ", cond.toArray())))
	+ " ORDER BY a.id ASC, c.user_nm DESC"
	, 1
);
DataSet next = homeworkUser.query(
	"SELECT a.id cuid, a.user_id u_id "
	+ ", b.* "
	+ ", c.user_nm, c.login_id "
	+ ", (SELECT GROUP_CONCAT(filename) FROM " + file.table + " WHERE module = 'homework_" + hid + "' AND module_id = a.id) as user_file "
	+ " FROM " + courseUser.table + " a "
	+ " LEFT JOIN " + homeworkUser.table + " b ON b.course_user_id = a.id AND b.homework_id = " + hid + " AND b.status = 1 "
	+ " INNER JOIN " + user.table + " c ON a.user_id = c.id " + (deptManagerBlock ? " AND c.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE a.id < " + cuid + " "
	+ " AND a.status IN (1,3) AND a.course_id = " + courseId + " "
	+ " AND " + (!"Y".equals(submitYn) ? "NOT" : "") + " EXISTS (SELECT 1 FROM " + homeworkUser.table + " WHERE course_user_id = a.id AND homework_id = " + hid + " AND status = 1) "
	+ (cond.isEmpty() ? "" : " AND " + (m.join(" AND ", cond.toArray())))
	+ " ORDER BY a.id DESC, c.user_nm ASC "
	, 1
);

if(prev.next()) {
	prev.put("subject_conv", m.cutString(m.htt(prev.s("subject")),  50));
	prev.put("mod_date", m.time("yyyy.MM.dd HH:mm", (!"".equals(prev.s("mod_date")) ? prev.s("mod_date") : prev.s("reg_date"))));
//	prev.put("filename_conv", m.cutString(prev.s("filename"), 28));
	prev.put("user_file_conv", m.cutString(prev.s("user_file"), 28));
}
if(next.next()) {
	next.put("subject_conv", m.cutString(m.htt(next.s("subject")), 50));
	next.put("mod_date", m.time("yyyy.MM.dd HH:mm", (!"".equals(next.s("mod_date")) ? next.s("mod_date") : next.s("reg_date"))));
//	next.put("filename_conv", m.cutString(next.s("filename"), 28));
	next.put("user_file_conv", m.cutString(next.s("user_file"), 28));
}

//출력
p.setLayout("pop");
p.setBody("management.homework_user_view");
p.setVar("p_title", "과제 평가");
p.setVar("query", m.qs("mode, tceuid"));
p.setVar("list_query", m.qs("mode,tceuid,cuid"));
p.setVar("form_script", f.getScript());

p.setVar("cid", courseId);
p.setVar("hid", hid);
p.setVar("cuid", cuid);
p.setVar("info", info);
p.setVar("dek", m.encrypt("del" + userId));
p.setVar("next", next);
p.setVar("prev", prev);

p.setLoop("files", files);
p.setLoop("task_list", taskList);
p.display();

%>
