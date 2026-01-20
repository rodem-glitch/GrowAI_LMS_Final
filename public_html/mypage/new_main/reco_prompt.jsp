<%@ page contentType="application/json; charset=utf-8" %>
<%@ include file="../../init.jsp" %><%

// 목적: 학생 개인 추천 프롬프트 저장/조회 API

StudentRecoPromptDao recoPrompt = new StudentRecoPromptDao();

if(userId <= 0) {
	out.print("{\"ok\":false,\"msg\":\"로그인이 필요합니다.\"}");
	return;
}

String prompt = m.rs("prompt").trim();
if(prompt.length() > 500) prompt = m.cutString(prompt, 500, "");
String jsonPrompt = m.replace(prompt, "\\", "\\\\");
jsonPrompt = m.replace(jsonPrompt, "\"", "\\\"");
jsonPrompt = m.replace(jsonPrompt, "\r", "");
jsonPrompt = m.replace(jsonPrompt, "\n", "\\n");

DataSet current = recoPrompt.find(
	"site_id = " + siteId + " AND user_id = " + userId + " AND status = 1",
	"prompt, id"
);

if(m.isPost()) {
	// 왜: 공백 저장은 "설정 해제"로 처리합니다.
	if("".equals(prompt)) {
		if(current.next()) {
			recoPrompt.item("status", 0);
			recoPrompt.item("mod_date", m.time("yyyyMMddHHmmss"));
			recoPrompt.update("id = " + current.i("id"));
		}
		out.print("{\"ok\":true,\"prompt\":\"\",\"msg\":\"저장 해제되었습니다.\"}");
		return;
	}

	if(current.next()) {
		recoPrompt.item("prompt", prompt);
		recoPrompt.item("mod_date", m.time("yyyyMMddHHmmss"));
		recoPrompt.update("id = " + current.i("id"));
	} else {
		recoPrompt.item("site_id", siteId);
		recoPrompt.item("user_id", userId);
		recoPrompt.item("prompt", prompt);
		recoPrompt.item("status", 1);
		recoPrompt.item("reg_date", m.time("yyyyMMddHHmmss"));
		recoPrompt.insert();
	}

	out.print("{\"ok\":true,\"prompt\":\"" + jsonPrompt + "\",\"msg\":\"저장되었습니다.\"}");
	return;
}

String saved = "";
if(current.next()) {
	saved = current.s("prompt");
}

String jsonSaved = m.replace(saved, "\\", "\\\\");
jsonSaved = m.replace(jsonSaved, "\"", "\\\"");
jsonSaved = m.replace(jsonSaved, "\r", "");
jsonSaved = m.replace(jsonSaved, "\n", "\\n");

out.print("{\"ok\":true,\"prompt\":\"" + jsonSaved + "\"}");
%>
