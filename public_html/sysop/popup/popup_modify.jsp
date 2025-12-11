<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(7, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//유효성검사
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
PopupDao popup = new PopupDao();

//정보
DataSet info = popup.find("id = " + id);
if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

//폼체크
f.addElement("subject", info.s("subject"), "hname:'제목', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y', allowiframe:'Y'");
f.addElement("width", info.i("width"), "hname:'너비', required:'Y', option:'number'");
f.addElement("height", info.i("height"), "hname:'높이', required:'Y', option:'number'");
f.addElement("left_pos", info.i("left_pos"), "hname:'좌측위치', option:'number'");
f.addElement("top_pos", info.i("top_pos"), "hname:'상단위치', option:'number'");
f.addElement("scrollbar_yn", info.s("scrollbar_yn"), "hname:'스크롤바사용여부', required:'Y'");
f.addElement("template_yn", info.s("template_yn"), "hname:'템플릿사용여부'");
f.addElement("layout", info.s("layout"), "hname:'레이아웃'");
f.addElement("start_date", m.time("yyyy-MM-dd", info.s("start_date")), "hname:'시작일', required:'Y'");
f.addElement("end_date", m.time("yyyy-MM-dd", info.s("end_date")), "hname:'종료일', required:'Y'");
f.addElement("status", info.i("status"), "hname:'노출여부', required:'Y', option:'number'");

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
	popup.item("status", f.getInt("status"));

	if(!popup.update("id = " + id)) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("popup_list.jsp?" + m.qs("id"), "parent");
	return;
}
info.put("popup_type_conv", m.getValue(info.s("popup_type"), popup.types));
info.put("content", m.htt(info.s("content")));

//출력
p.setBody("popup.popup_insert");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());
p.setVar("modify", true);
p.setVar("temp_id", id);
p.setVar(info);
p.setLoop("scroll_list", m.arr2loop(popup.scrollList));
p.setLoop("template_list", m.arr2loop(popup.templateList));
p.setLoop("layout_list", m.arr2loop(popup.layoutList));
p.setLoop("status_list", m.arr2loop(popup.statusList));
p.display();

%>