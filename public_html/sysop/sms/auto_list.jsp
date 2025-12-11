<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(42, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SendAutoDao sendAuto = new SendAutoDao();

//폼체크
f.addElement("s_sms", null, null);
f.addElement("s_email", null, null);
f.addElement("s_msg", null, null);

f.addElement("s_send_type", null, null);
f.addElement("s_status", null, null);
f.addElement("s_homework", null, null);
f.addElement("s_exam", null, null);

f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(sendAuto.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");

lm.addSearch("a.sms_yn", f.get("s_sms"));
lm.addSearch("a.email_yn", f.get("s_email"));
lm.addSearch("a.msg_yn", f.get("s_msg"));

lm.addSearch("a.homework_yn", f.get("s_homework"));
lm.addSearch("a.exam_yn", f.get("s_exam"));
lm.addSearch("a.status", f.get("s_status"));
lm.addSearch("a.send_type", f.get("s_send_type"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.subject,a.sms_content,a.email_content", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("subject_conv", m.cutString(list.s("subject"), 50));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));

	list.put("status_conv", m.getItem(list.s("status"), sendAuto.statusList));
	list.put("homework_conv", m.getItem(list.s("homework_yn"), sendAuto.atypes));
	list.put("exam_conv", m.getItem(list.s("exam_yn"), sendAuto.atypes));
	list.put("std_type_conv", m.getItem(list.s("std_type"), sendAuto.stypes));

	list.put("min_ratio_conv", m.nf(list.d("min_ratio"),0));
	list.put("max_ratio_conv", m.nf(list.d("max_ratio"),0));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "학습독려관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>독려번호", "auto_nm=>학습독려명", "subject=>이메일제목", "email_yn=>메일여부", "sms_yn=>SMS여부", "min_ratio_conv=>최소진도율", "max_ratio_conv=>최대진도율", "homework_conv=>과제기준", "exam_conv=>시험기준", "std_type_conv=>기준구분", "std_day=>기준일", "reg_date_conv=>등록일", "status_conv=>상태" }, "학습독려관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("sms.auto_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(sendAuto.statusList));
p.setLoop("homework_list", m.arr2loop(sendAuto.homeworkList));
p.setLoop("exam_list", m.arr2loop(sendAuto.examList));
p.display();

%>