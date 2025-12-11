<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(7, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
FileDao file = new FileDao();
PopupDao popup = new PopupDao();

//폼체크
f.addElement("popup_type", "pc", "hname:'팝업유형', required:'Y'");
f.addElement("subject", null, "hname:'제목', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y', allowiframe:'Y'");
f.addElement("width", 400, "hname:'너비', required:'Y', option:'number'");
f.addElement("height", 500, "hname:'높이', required:'Y', option:'number'");
f.addElement("left_pos", 0, "hname:'좌측위치', option:'number'");
f.addElement("top_pos", 0, "hname:'상단위치', option:'number'");
f.addElement("scrollbar_yn", "N", "hname:'스크롤바사용여부', required:'Y'");
f.addElement("template_yn", "N", "hname:'템플릿사용여부'");
f.addElement("layout", null, "hname:'레이아웃'");
f.addElement("start_date", null, "hname:'시작일', required:'Y'");
f.addElement("end_date", null, "hname:'종료일', required:'Y'");
f.addElement("status", 0, "hname:'노출여부', required:'Y', option:'number'");

if(m.isPost() && f.validate()) {

	String content = f.get("content");
	//제한-이미지URI
	if(-1 < content.indexOf("<img") && -1 < content.indexOf("data:image/") && -1 < content.indexOf("base64")) {
		m.jsAlert("이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}

	//제한-용량
	int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(60000 < bytes) {
		m.jsAlert("내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes + "바이트)");
		return;
	}

	popup.item("popup_type", f.get("popup_type"));
	popup.item("site_id", siteinfo.i("id"));
	popup.item("subject", f.get("subject"));
	popup.item("content", content);
	popup.item("width", f.getInt("width"));
	popup.item("height", f.getInt("height"));
	popup.item("left_pos", f.getInt("left_pos"));
	popup.item("top_pos", f.getInt("top_pos"));
	popup.item("scrollbar_yn", f.get("scrollbar_yn"));
	popup.item("template_yn", f.get("template_yn", "Y"));
	popup.item("layout", "N".equals(f.get("template_yn")) ? "" : f.get("layout", "pop1"));
	popup.item("start_date", m.time("yyyyMMdd", f.get("start_date")));
	popup.item("end_date", m.time("yyyyMMdd", f.get("end_date")));
	popup.item("reg_date", m.time("yyyyMMddHHmmss"));
	popup.item("status", f.getInt("status"));

	if(!popup.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	file.updateTempFile(f.getInt("popup_id"), popup.getInsertId(), "popup");

	m.jsReplace("popup_list.jsp?" + m.qs(), "parent");
	return;
}

//출력
p.setBody("popup.popup_insert");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());
p.setVar("temp_id", m.getRandInt(-2000000, 1990000));
p.setLoop("scroll_list", m.arr2loop(popup.scrollList));
p.setLoop("template_list", m.arr2loop(popup.templateList));
p.setLoop("layout_list", m.arr2loop(popup.layoutList));
p.setLoop("status_list", m.arr2loop(popup.statusList));
p.setLoop("types", m.arr2loop(popup.types));
p.display();

%>