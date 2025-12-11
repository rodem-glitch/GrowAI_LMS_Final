<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(42, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
SendAutoDao sendAuto = new SendAutoDao();

//정보
DataSet info = sendAuto.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//폼체크
f.addElement("sms_yn", info.s("sms_yn"), "hname:'SMS사용여부'");
f.addElement("email_yn", info.s("email_yn"), "hname:'이메일사용여부'");

f.addElement("std_type", info.s("std_type"), "hname:'기준일구분', required:'Y'");
f.addElement("std_day", info.i("std_day"), "hname:'기준일', required:'Y', option:'number'");

f.addElement("auto_nm", info.s("auto_nm"), "hname:'학습독려명', required:'Y'");
f.addElement("subject", info.s("subject"), "hname:'제목', required:'Y'");

f.addElement("min_ratio", m.nf(info.d("min_ratio"),0), "hname:'최소진도율', required:'Y', option:'number'");
f.addElement("max_ratio", m.nf(info.d("max_ratio"),0), "hname:'최대진도율', required:'Y', option:'number'");

f.addElement("homework_yn", info.s("homework_yn"), "hname:'과제', required:'Y'");
f.addElement("exam_yn", info.s("exam_yn"), "hname:'최종평가', required:'Y'");
f.addElement("status", info.i("status"), "hname:'상태', required:'Y', option:'number'");

//등록
if(m.isPost() && f.validate()) {

	sendAuto.item("std_type", f.get("std_type"));
	sendAuto.item("std_day", f.getInt("std_day", 0));

	sendAuto.item("sms_yn", f.get("sms_yn", "N"));
	sendAuto.item("email_yn", f.get("email_yn", "N"));
	sendAuto.item("msg_yn", f.get("msg_yn", "N"));

	sendAuto.item("auto_nm", f.get("auto_nm"));
	sendAuto.item("subject", f.get("subject"));
	sendAuto.item("sms_content", f.get("sms_content"));
	sendAuto.item("email_content", f.get("email_content"));

	sendAuto.item("min_ratio", f.get("min_ratio", "0.00"));
	sendAuto.item("max_ratio", f.get("max_ratio", "0.00"));

	sendAuto.item("homework_yn", f.get("homework_yn", "-"));
	sendAuto.item("exam_yn", f.get("exam_yn", "-"));
	sendAuto.item("status", f.getInt("status"));

	if(!sendAuto.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("auto_list.jsp", "parent");
	return;
}

//목록
DataSet days = new DataSet();
for(int i = -30;i <= 70; i++) {
	days.addRow();
	days.put("day", i);
	days.put("day_nm", i == 0 ? "당일" : i + "일");
}

//출력
p.setBody("sms.auto_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);
p.setVar("tab_modify", "current");
p.setVar("aid", id);

p.setLoop("status_list", m.arr2loop(sendAuto.statusList));
p.setLoop("types", m.arr2loop(sendAuto.types));
p.setLoop("days", days);
p.display();

%>