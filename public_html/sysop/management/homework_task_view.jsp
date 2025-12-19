<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본값
int hid = m.ri("hid"); //과제ID(LM_HOMEWORK.ID)
int cuid = m.ri("cuid"); //수강ID(LM_COURSE_USER.ID)
int tid = m.ri("tid"); //추가과제ID(LM_HOMEWORK_TASK.ID)
if(hid == 0 || cuid == 0 || courseId == 0) { m.jsError("기본값은 반드시 지정해야 합니다."); return; }

//객체
HomeworkTaskDao homeworkTask = new HomeworkTaskDao();
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
HomeworkDao homework = new HomeworkDao();
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();
ClFileDao file = new ClFileDao();

//변수
String now = m.time("yyyyMMddHHmmss");
String mode = m.rs("mode");

//정보-과제(과정에 배치된 과제인지 확인)
DataSet hinfo = courseModule.query(
	"SELECT a.course_id, a.apply_type, a.start_date, a.end_date, a.chapter, a.assign_score "
	+ ", h.homework_nm, h.onoff_type "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + homework.table + " h ON a.module_id = h.id AND h.status != -1 "
	+ " WHERE a.status = 1 AND a.module = 'homework' "
	+ " AND a.course_id = " + courseId + " AND a.module_id = " + hid + " AND h.site_id = " + siteId + " "
);
if(!hinfo.next()) { m.jsError("해당 과제 정보가 없습니다."); return; }

//정보-수강생(부서권한 포함)
DataSet uinfo = courseUser.query(
	"SELECT a.id course_user_id, a.user_id, u.user_nm, u.login_id "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id "
	+ (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE a.id = " + cuid + " AND a.course_id = " + courseId + " AND a.status IN (1,3) "
);
if(!uinfo.next()) { m.jsError("해당 수강 정보가 없습니다."); return; }
user.maskInfo(uinfo);

//보안토큰(팝업에서 링크로 삭제/초기화할 때 악의적 호출을 막기 위함)
String dek = m.encrypt("del" + userId);
String fdek = m.encrypt("fdel" + userId);

//처리-피드백초기화
if("fdel".equals(mode) && tid > 0) {
	if(!fdek.equals(m.rs("dek"))) { m.jsError("올바르지 않은 요청입니다."); return; }

	DataSet tinfo = homeworkTask.find("id = " + tid + " AND site_id = " + siteId + " AND course_id = " + courseId + " AND homework_id = " + hid + " AND course_user_id = " + cuid + " AND status = 1");
	if(!tinfo.next()) { m.jsError("해당 추가 과제 정보가 없습니다."); return; }

	homeworkTask.item("feedback", "");
	homeworkTask.item("confirm_yn", "N");
	homeworkTask.item("confirm_user_id", userId);
	homeworkTask.item("confirm_date", "");
	homeworkTask.item("mod_date", now);
	if(!homeworkTask.update("id = " + tid + "")) { m.jsError("피드백 초기화 중 오류가 발생했습니다."); return; }

	m.jsAlert("피드백을 초기화했습니다.");
	m.jsReplace("homework_task_view.jsp?" + m.qs("mode"), "parent");
	return;
}

//처리-추가과제삭제
if("del".equals(mode) && tid > 0) {
	if(!dek.equals(m.rs("dek"))) { m.jsError("올바르지 않은 요청입니다."); return; }

	DataSet tinfo = homeworkTask.find("id = " + tid + " AND site_id = " + siteId + " AND course_id = " + courseId + " AND homework_id = " + hid + " AND course_user_id = " + cuid + " AND status = 1");
	if(!tinfo.next()) { m.jsError("해당 추가 과제 정보가 없습니다."); return; }

	homeworkTask.item("status", -1);
	homeworkTask.item("mod_date", now);
	if(!homeworkTask.update("id = " + tid + "")) { m.jsError("삭제 중 오류가 발생했습니다."); return; }

	//연결된 첨부파일 삭제
	file.execute("DELETE FROM " + file.table + " WHERE module = 'homework_task_assign_" + tid + "' AND module_id = " + cuid + "");
	file.execute("DELETE FROM " + file.table + " WHERE module = 'homework_task_" + tid + "' AND module_id = " + cuid + "");
	file.execute("DELETE FROM " + file.table + " WHERE module = 'homework_task_feedback_" + tid + "' AND module_id = " + cuid + "");

	m.jsAlert("삭제했습니다.");
	m.js("try { opener.location.reload(); } catch(e) {} window.close();");
	return;
}

//처리-등록/수정/피드백저장 (POST)
if(m.isPost()) {
	//추가과제 등록/수정
	if("add".equals(mode) || "mod".equals(mode)) {
		f.addElement("task", null, "hname:'추가 과제', required:'Y', allowhtml:'Y'");

		if(f.validate()) {
			String taskContent = f.get("task");
			//왜: base64 이미지가 들어오면 DB 용량/렌더링 문제로 장애가 생길 수 있어서 선제 차단합니다.
			if(-1 < taskContent.indexOf("<img") && -1 < taskContent.indexOf("data:image/") && -1 < taskContent.indexOf("base64")) {
				m.jsAlert("이미지는 첨부파일 기능으로 업로드해 주세요.");
				return;
			}
			int bytes = taskContent.replace("\r\n", "\n").getBytes("UTF-8").length;
			if(60000 < bytes) { m.jsAlert("내용은 60000바이트를 초과할 수 없습니다.\\n(현재 " + bytes + "바이트)"); return; }

			if("add".equals(mode)) {
				//왜: 학생별로 여러 번 반복될 수 있어서, 이전 추가 과제와 연결(parent_id)만 저장해 타임라인을 만들 수 있게 합니다.
				int parentId = homeworkTask.getOneInt(
					"SELECT MAX(id) "
					+ " FROM " + homeworkTask.table + " "
					+ " WHERE site_id = " + siteId + " AND course_id = " + courseId + " AND homework_id = " + hid + " AND course_user_id = " + cuid + " AND status = 1 "
				);

				int newId = homeworkTask.getSequence();
				homeworkTask.item("id", newId);
				homeworkTask.item("site_id", siteId);
				homeworkTask.item("course_id", courseId);
				homeworkTask.item("homework_id", hid);
				homeworkTask.item("course_user_id", cuid);
				homeworkTask.item("user_id", uinfo.i("user_id"));
				homeworkTask.item("parent_id", parentId);
				homeworkTask.item("assign_user_id", userId);
				homeworkTask.item("task", taskContent);
				homeworkTask.item("submit_yn", "N");
				homeworkTask.item("confirm_yn", "N");
				homeworkTask.item("feedback", "");
				homeworkTask.item("ip_addr", userIp);
				homeworkTask.item("reg_date", now);
				homeworkTask.item("mod_date", now);
				homeworkTask.item("status", 1);
				if(!homeworkTask.insert()) { m.jsError("등록 중 오류가 발생했습니다."); return; }

				//첨부파일 모듈 업데이트 (tid=0 → newId)
				file.execute("UPDATE " + file.table + " SET module = 'homework_task_assign_" + newId + "' WHERE module = 'homework_task_assign_0' AND module_id = " + cuid + "");

				m.jsAlert("추가 과제를 등록했습니다.");
				m.jsReplace("homework_task_view.jsp?cid=" + courseId + "&hid=" + hid + "&cuid=" + cuid + "&tid=" + newId, "parent");
				return;

			} else {
				if(tid == 0) { m.jsError("기본값은 반드시 지정해야 합니다."); return; }

				DataSet tinfo = homeworkTask.find("id = " + tid + " AND site_id = " + siteId + " AND course_id = " + courseId + " AND homework_id = " + hid + " AND course_user_id = " + cuid + " AND status = 1");
				if(!tinfo.next()) { m.jsError("해당 추가 과제 정보가 없습니다."); return; }

				homeworkTask.item("task", taskContent);
				homeworkTask.item("mod_date", now);
				if(!homeworkTask.update("id = " + tid + "")) { m.jsError("수정 중 오류가 발생했습니다."); return; }

				m.jsAlert("수정했습니다.");
				m.jsReplace("homework_task_view.jsp?" + m.qs("mode"), "parent");
				return;
			}
		}

	//피드백 저장
	} else if("feedback".equals(mode)) {
		if(tid == 0) { m.jsError("기본값은 반드시 지정해야 합니다."); return; }

		f.addElement("feedback", null, "hname:'피드백', allowhtml:'Y'");

		if(f.validate()) {
			String feedback = f.get("feedback");
			//왜: base64 이미지는 DB에 누적되면 용량 폭증/오류가 나기 쉽습니다.
			if(-1 < feedback.indexOf("<img") && -1 < feedback.indexOf("data:image/") && -1 < feedback.indexOf("base64")) {
				m.jsAlert("이미지는 첨부파일 기능으로 업로드해 주세요.");
				return;
			}
			int bytes = feedback.replace("\r\n", "\n").getBytes("UTF-8").length;
			if(60000 < bytes) { m.jsAlert("내용은 60000바이트를 초과할 수 없습니다.\\n(현재 " + bytes + "바이트)"); return; }

			DataSet tinfo = homeworkTask.find("id = " + tid + " AND site_id = " + siteId + " AND course_id = " + courseId + " AND homework_id = " + hid + " AND course_user_id = " + cuid + " AND status = 1");
			if(!tinfo.next()) { m.jsError("해당 추가 과제 정보가 없습니다."); return; }

			homeworkTask.item("feedback", feedback);
			homeworkTask.item("confirm_yn", "Y");
			homeworkTask.item("confirm_user_id", userId);
			homeworkTask.item("confirm_date", now);
			homeworkTask.item("mod_date", now);
			if(!homeworkTask.update("id = " + tid + "")) { m.jsError("피드백 저장 중 오류가 발생했습니다."); return; }

			//다음 추가과제 함께 부여 (next_task가 있으면)
			String nextTask = f.get("next_task");
			if(nextTask != null && !"".equals(nextTask.trim())) {
				//왜: base64 이미지 차단
				if(-1 < nextTask.indexOf("<img") && -1 < nextTask.indexOf("data:image/") && -1 < nextTask.indexOf("base64")) {
					m.jsAlert("다음 추가과제에 이미지는 첨부파일 기능으로 업로드해 주세요.");
					return;
				}
				int nextBytes = nextTask.replace("\r\n", "\n").getBytes("UTF-8").length;
				if(60000 < nextBytes) { m.jsAlert("다음 추가과제 내용은 60000바이트를 초과할 수 없습니다.\\n(현재 " + nextBytes + "바이트)"); return; }

				int newId = homeworkTask.getSequence();
				homeworkTask.item("id", newId);
				homeworkTask.item("site_id", siteId);
				homeworkTask.item("course_id", courseId);
				homeworkTask.item("homework_id", hid);
				homeworkTask.item("course_user_id", cuid);
				homeworkTask.item("user_id", uinfo.i("user_id"));
				homeworkTask.item("parent_id", tid);
				homeworkTask.item("assign_user_id", userId);
				homeworkTask.item("task", nextTask);
				homeworkTask.item("submit_yn", "N");
				homeworkTask.item("confirm_yn", "N");
				homeworkTask.item("feedback", "");
				homeworkTask.item("ip_addr", userIp);
				homeworkTask.item("reg_date", now);
				homeworkTask.item("mod_date", now);
				homeworkTask.item("status", 1);
				if(!homeworkTask.insert()) { m.jsError("다음 추가과제 등록 중 오류가 발생했습니다."); return; }

			//첨부파일 모듈 업데이트 (임시 homework_task_assign_next_tid → 실제 homework_task_assign_newId)
			file.execute("UPDATE " + file.table + " SET module = 'homework_task_assign_" + newId + "' WHERE module = 'homework_task_assign_next_" + tid + "' AND module_id = " + cuid + "");

				m.jsAlert("피드백을 저장하고 다음 추가과제를 부여했습니다.");
				m.jsReplace("homework_task_view.jsp?cid=" + courseId + "&hid=" + hid + "&cuid=" + cuid + "&tid=" + newId, "parent");
				return;
			}

			m.jsAlert("피드백을 저장했습니다.");
			m.jsReplace("homework_task_view.jsp?" + m.qs("mode"), "parent");
			return;
		}
	}
}

//정보-추가과제
DataSet info = new DataSet();
if(tid > 0) {
	info = homeworkTask.find("id = " + tid + " AND site_id = " + siteId + " AND course_id = " + courseId + " AND homework_id = " + hid + " AND course_user_id = " + cuid + " AND status = 1");
	if(!info.next()) { m.jsError("해당 추가 과제 정보가 없습니다."); return; }
} else {
	info.addRow();
	info.put("submit_yn", "N");
	info.put("confirm_yn", "N");
}

info.put("reg_date_conv", !"".equals(info.s("reg_date")) ? m.time("yyyy.MM.dd HH:mm", info.s("reg_date")) : "-");
info.put("submit_date_conv", !"".equals(info.s("submit_date")) ? m.time("yyyy.MM.dd HH:mm", info.s("submit_date")) : "-");
info.put("confirm_date_conv", !"".equals(info.s("confirm_date")) ? m.time("yyyy.MM.dd HH:mm", info.s("confirm_date")) : "-");

info.put("task_conv", m.htt(info.s("task")));
info.put("content_conv", m.htt(info.s("content")));
info.put("feedback_conv", m.htt(info.s("feedback")));

info.put("submit_block", "Y".equals(info.s("submit_yn")));
info.put("confirm_block", "Y".equals(info.s("confirm_yn")));
info.put("add_block", tid == 0);
info.put("mod_block", tid > 0);

//첨부파일-추가과제(부여)
DataSet assignFiles = new DataSet();
DataSet submitFiles = new DataSet();
DataSet feedbackFiles = new DataSet();
if(tid > 0) {
	assignFiles = file.find("module = 'homework_task_assign_" + tid + "' AND module_id = " + cuid + " AND status = 1");
	while(assignFiles.next()) {
		assignFiles.put("ext", file.getFileIcon(assignFiles.s("filename")));
		assignFiles.put("ek", m.encrypt(assignFiles.s("filename") + m.time("yyyyMMdd")));
		assignFiles.put("filename_conv", m.encode(assignFiles.s("filename")));
	}

	submitFiles = file.find("module = 'homework_task_" + tid + "' AND module_id = " + cuid + " AND status = 1");
	while(submitFiles.next()) {
		submitFiles.put("ext", file.getFileIcon(submitFiles.s("filename")));
		submitFiles.put("ek", m.encrypt(submitFiles.s("filename") + m.time("yyyyMMdd")));
		submitFiles.put("filename_conv", m.encode(submitFiles.s("filename")));
	}

	feedbackFiles = file.find("module = 'homework_task_feedback_" + tid + "' AND module_id = " + cuid + " AND status = 1");
	while(feedbackFiles.next()) {
		feedbackFiles.put("ext", file.getFileIcon(feedbackFiles.s("filename")));
		feedbackFiles.put("ek", m.encrypt(feedbackFiles.s("filename") + m.time("yyyyMMdd")));
		feedbackFiles.put("filename_conv", m.encode(feedbackFiles.s("filename")));
	}
}

//출력
p.setLayout("pop");
p.setBody("management.homework_task_view");
p.setVar("p_title", "추가 과제 관리");
p.setVar("query", m.qs("mode"));
p.setVar("form_script", f.getScript());

p.setVar("cid", courseId);
p.setVar("hid", hid);
p.setVar("cuid", cuid);
p.setVar("tid", tid);
p.setVar("dek", dek);
p.setVar("fdek", fdek);

p.setVar("homework", hinfo);
p.setVar("user", uinfo);
p.setVar("info", info);

p.setLoop("assign_files", assignFiles);
p.setLoop("submit_files", submitFiles);
p.setLoop("feedback_files", feedbackFiles);
p.display();

%>
