<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(91, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(1 > id) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
MainpageDao mainpage = new MainpageDao();
//mainpage.d(out);

//정보
DataSet info = mainpage.find("id = " + id + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("module_type_conv", m.getItem(info.s("module_type"), mainpage.modules));

//폼체크
f.addElement("module_nm", info.s("module_nm"), "hname:'항목명', required:'Y'");
f.addElement("display_yn", info.s("display_yn"), "hname:'노출여부', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	mainpage.item("module_nm", f.get("module_nm"));
	mainpage.item("module_params", Json.encode(m.reqMap("md_")));
	mainpage.item("display_yn", f.get("display_yn"));

	if(!mainpage.update("id = " + id)) {
		m.jsAlert("수정하는 중 오류가 발생했습니다.");
		return;
	}

	//이동
	m.jsReplace("mainpage_list.jsp?mid=" + id, "parent.parent");
	return;

}

//포맷팅
if(!"".equals(info.s("module_params"))) {
	HashMap<String, Object> sub = Json.toMap(info.s("module_params"));
	for(String key : sub.keySet()) {
		info.put(key, sub.get(key).toString());
		f.addElement(key, sub.get(key).toString(), null);
	}
}

//출력
//p.setDebug();
p.setLayout("blank");
p.setBody("design.mainpage_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setVar("modify", true);
/*
p.setLoop("types", banner.query("SELECT DISTINCT banner_type FROM " + banner.table + " WHERE banner_type NOT IN ('main', 'mobile') AND site_id = " + siteId + " AND status != -1"));
p.setLoop("targets", m.arr2loop(banner.targets));
p.setLoop("sorts", sortList);
p.setLoop("status_list", m.arr2loop(banner.statusList));
*/
p.display();

%>