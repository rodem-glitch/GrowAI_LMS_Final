<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(7, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
PopupDao popup = new PopupDao();

//폼체크
f.addElement("s_popup_type", null, null);
f.addElement("s_sdate", null, null);
f.addElement("s_edate", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

String today = m.time("yyyyMMdd");

//목록
ListManager lm = new ListManager();
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(popup.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status > -1");
lm.addWhere("a.site_id = " + siteinfo.i("id"));
lm.addSearch("a.popup_type", m.rs("s_popup_type"));
lm.addSearch("a.start_date", m.time("yyyyMMdd", f.get("s_sdate")), ">=");
lm.addSearch("a.end_date", m.time("yyyyMMdd", f.get("s_edate")), "<=");

if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.subject, a.content", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

//정보
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("popup_type_conv", m.getValue(list.s("popup_type"), popup.types));
	list.put("subject_conv", m.cutString(list.s("subject"), 50));
	list.put("start_date_conv", m.time("yyyy.MM.dd", list.s("start_date")));
	list.put("end_date_conv", m.time("yyyy.MM.dd", list.s("end_date")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", list.i("status") == 0 ? "미사용" : (m.parseInt(list.s("start_date")) <= m.parseInt(today) && m.parseInt(list.s("end_date")) >= m.parseInt(today)) ? "진행" : m.parseInt(list.s("start_date")) > m.parseInt(today) ? "대기" : "종료");
	list.put("height", list.i("height") + 101);
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "팝업관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[]{ "__ord=>고유값", "subject=>제목", "content=>내용", "start_date_conv=>시작일", "end_date_conv=>종료일", "reg_date_conv=>등록일", "status_conv=>노출여부", "width=>창너비", "height=>창높이", "top_pos=>상단위치", "left_pos=>좌측위치", "scrollbar_yn=>스크롤바 사용여부", "template_yn=>템플릿 사용여부", "layout=>레이아웃"});
	ex.write();
	return;
}

//출력
p.setBody("popup.popup_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setLoop("types", m.arr2loop(popup.types));
p.display();

%>