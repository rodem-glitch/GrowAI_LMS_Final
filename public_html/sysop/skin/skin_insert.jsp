<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(10, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SiteSkinDao siteSkin = new SiteSkinDao();

//폼체크
f.addElement("skin_nm", null, "hname:'스킨명', required:'Y'");
f.addElement("tpl_root", null, "hname:'HTML 시작 경로', required:'Y'");
f.addElement("base_yn", "N", "hname:'기본스킨여부', required:'Y'");
f.addElement("main_img", null, "hname:'메인이미지', allow:'jpg|jpeg|gif|png'");
f.addElement("sub_img", null, "hname:'서브이미지', allow:'jpg|jpeg|gif|png'");
f.addElement("status", 1, "hname:'상태', required:'Y', option:'number'"); 

//등록
if(m.isPost() && f.validate()) {

	int newId = siteSkin.getSequence();
	
	siteSkin.item("id", newId);
	siteSkin.item("skin_nm", f.get("skin_nm"));
	siteSkin.item("tpl_root", f.get("tpl_root"));
	if("Y".equals(f.get("base_yn"))) {
		siteSkin.execute("UPDATE " + siteSkin.table + " SET base_yn = 'N'");
		siteSkin.item("base_yn", "Y");
	} else { siteSkin.item("base_yn", "N"); }
	siteSkin.item("reg_date", m.time("yyyyMMddHHmmss"));
	siteSkin.item("status", f.getInt("status"));
	
	if(f.getFileName("main_img") != null) {
		File main_img = f.saveFile("main_img");
		if(main_img != null) { siteSkin.item("main_img", f.getFileName("main_img")); }
	}
	if(f.getFileName("sub_img") != null) {
		File main_img = f.saveFile("sub_img");
		if(main_img != null) { siteSkin.item("sub_img", f.getFileName("sub_img")); }
	}
	
	if(!siteSkin.insert()) {
		m.jsAlert("등록하는 중 오류가 발생했습니다.");
		return;
	}

	m.jsReplace("skin_list.jsp", "parent");
	return;
}

//출력
p.setBody("skin.skin_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("status_list", m.arr2loop(siteSkin.statusList));
p.display();

%>