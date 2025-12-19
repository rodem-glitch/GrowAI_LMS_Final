<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

int hid = m.reqInt("hid");
int tid = m.reqInt("tid");
if(hid == 0 || tid == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
HomeworkDao homework = new HomeworkDao();
HomeworkTaskDao homeworkTask = new HomeworkTaskDao();
CourseProgressDao courseProgress = new CourseProgressDao();
ClFileDao file = new ClFileDao();

//정보-과제(제출 가능 기간 계산용)
DataSet hinfo = courseModule.query(
	"SELECT a.*, h.homework_nm, h.onoff_type "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + homework.table + " h ON a.module_id = h.id AND h.status != -1 AND h.id = " + hid + " "
	+ " WHERE a.status = 1 AND a.module = 'homework' "
	+ " AND a.course_id = " + courseId + " AND h.site_id = " + siteId + ""
);
if(!hinfo.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

//정보-추가과제
DataSet info = homeworkTask.find(
	"id = " + tid + " AND site_id = " + siteId + " AND course_id = " + courseId + " AND homework_id = " + hid + " AND course_user_id = " + cuid + " AND status = 1"
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

//포맷팅(기본 과제의 기간/차시 규칙을 그대로 따라갑니다)
boolean isReady = false; //대기
boolean isEnd = false; //완료
if("1".equals(hinfo.s("apply_type"))) { //기간
	hinfo.put("start_date_conv", m.time(_message.get("format.datetime.dot"), hinfo.s("start_date")));
	hinfo.put("end_date_conv",
		hinfo.s("start_date").substring(0, 8).equals(hinfo.s("end_date").substring(0, 8))
		? m.time("HH:mm", hinfo.s("end_date"))
		: m.time(_message.get("format.datetime.dot"), hinfo.s("end_date"))
	);

	isReady = 0 > m.diffDate("I", hinfo.s("start_date"), now);
	isEnd = 0 < m.diffDate("I", hinfo.s("end_date"), now);

	hinfo.put("apply_type_1", true);
	hinfo.put("apply_type_2", false);
} else if("2".equals(hinfo.s("apply_type"))) { //차시
	hinfo.put("apply_conv", hinfo.i("chapter") == 0 ? _message.get("classroom.module.before_study") : _message.get("classroom.module.after_study", new String[] { "chapter=>" + hinfo.i("chapter") }));
	if(hinfo.i("chapter") > 0 && 0 == courseProgress.findCount("course_id = " + courseId + " AND chapter = " + hinfo.i("chapter") + " AND course_user_id = " + cuid + " AND complete_yn = 'Y'")) isReady = true;

	hinfo.put("apply_type_1", false);
	hinfo.put("apply_type_2", true);
}

//왜: 기본 과제는 '평가완료(confirm_yn)' 이후 수정이 막히는데, 추가 과제도 같은 기준으로 제출/수정을 막아야 혼선이 없습니다.
boolean isOpen = !isReady && !isEnd && "I".equals(progress) && !info.b("confirm_yn") && "N".equals(hinfo.s("onoff_type"));
info.put("open_block", isOpen);

//폼객체
f.addElement("subject", info.s("subject"), "hname:'제목', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");

//제출/수정
if(m.isPost() && f.validate()) {

	if(!isOpen) { m.jsAlert(_message.get("alert.common.abnormal_access")); return; }

	String content = f.get("content");
	//제한-이미지URI및용량
	int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(-1 < content.indexOf("<img") && -1 < content.indexOf("data:image/") && -1 < content.indexOf("base64")) {
		m.jsAlert(_message.get("alert.board.attach_image"));
		return;
	}
	if(60000 < bytes) { m.jsAlert(_message.get("alert.board.over_capacity", new String[] {"maximum=>60000", "bytes=>" + bytes})); return; }

	homeworkTask.item("subject", f.get("subject"));
	homeworkTask.item("content", content);
	homeworkTask.item("submit_yn", "Y");
	homeworkTask.item("submit_date", m.time("yyyyMMddHHmmss"));
	homeworkTask.item("ip_addr", userIp);
	homeworkTask.item("mod_date", m.time("yyyyMMddHHmmss"));

	if(!homeworkTask.update("id = " + tid + " AND homework_id = " + hid + " AND course_user_id = " + cuid + "")) {
		m.jsAlert(_message.get("alert.common.error_modify")); return;
	}

	m.jsAlert("제출이 완료되었습니다.");
	m.jsReplace("homework_task_view.jsp?cuid=" + cuid + "&hid=" + hid + "&tid=" + tid, "parent");
	return;
}

//포맷팅
info.put("reg_date_conv", !"".equals(info.s("reg_date")) ? m.time(_message.get("format.datetime.dot"), info.s("reg_date")) : "-");
info.put("submit_date_conv", !"".equals(info.s("submit_date")) ? m.time(_message.get("format.datetime.dot"), info.s("submit_date")) : "-");
info.put("content_conv", m.htt(info.s("content")));
info.put("task_conv", m.htt(info.s("task")));
info.put("feedback", info.b("confirm_yn") ? info.s("feedback") : "-");

//목록-추가과제 첨부파일(부여)
DataSet assignFiles = file.find("module = 'homework_task_assign_" + tid + "' AND module_id = " + cuid + " AND status = 1");
while(assignFiles.next()) {
	assignFiles.put("ext", m.replace(file.getFileIcon(assignFiles.s("filename")), "../html/images/admin/ext/unknown.gif", "/common/images/ext/unknown.gif"));
	assignFiles.put("ek", m.encrypt(assignFiles.s("id")));
}

//목록-제출 첨부파일
DataSet submitFiles = file.find("module = 'homework_task_" + tid + "' AND module_id = " + cuid + " AND status = 1");
while(submitFiles.next()) {
	submitFiles.put("ext", m.replace(file.getFileIcon(submitFiles.s("filename")), "../html/images/admin/ext/unknown.gif", "/common/images/ext/unknown.gif"));
	submitFiles.put("ek", m.encrypt(submitFiles.s("id")));
}

//목록-피드백 첨부파일
DataSet feedbackFiles = file.find("module = 'homework_task_feedback_" + tid + "' AND module_id = " + cuid + " AND status = 1");
while(feedbackFiles.next()) {
	feedbackFiles.put("ext", m.replace(file.getFileIcon(feedbackFiles.s("filename")), "../html/images/admin/ext/unknown.gif", "/common/images/ext/unknown.gif"));
	feedbackFiles.put("ek", m.encrypt(feedbackFiles.s("id")));
}

//출력
p.setLayout(ch);
p.setBody("classroom.homework_task_view");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("tid,hid"));
p.setVar("form_script", f.getScript());

p.setVar("hid", hid);
p.setVar("tid", tid);
p.setVar("cuid", cuid);

p.setVar("homework", hinfo);
p.setVar("task", info);

p.setLoop("assign_files", assignFiles);
p.setLoop("submit_files", submitFiles);
p.setLoop("feedback_files", feedbackFiles);
p.display();

%>
