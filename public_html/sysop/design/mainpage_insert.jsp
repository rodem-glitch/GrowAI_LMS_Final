<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(91, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
MainpageDao mainpage = new MainpageDao();
//mainpage.d(out);

//변수
int maxSort = mainpage.findCount("site_id = " + siteId + " AND status != -1");

//폼입력
String moduleType = m.rs("module_type");

//폼체크
f.addElement("module_nm", null, "hname:'항목명', required:'Y'");
f.addElement("module_type", moduleType, "hname:'모듈', required:'Y'");
f.addElement("display_yn", "N", "hname:'노출여부', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	mainpage.item("site_id", siteId);
	mainpage.item("module_nm", f.get("module_nm"));
	mainpage.item("module_type", f.get("module_type"));
	mainpage.item("module_params", Json.encode(m.reqMap("md_")));
	mainpage.item("sort", maxSort + 1);
	mainpage.item("display_yn", f.get("display_yn"));
	mainpage.item("reg_date", sysNow);
	mainpage.item("status", 1);

	if(!mainpage.insert()) {
		m.jsAlert("등록하는 중 오류가 발생했습니다.");
		return;
	}

	//이동
	m.jsReplace("mainpage_list.jsp", "parent.parent");
	return;

}

//출력
p.setLayout("blank");
p.setBody("design.mainpage_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("modules", m.arr2loop(mainpage.modules));
p.display();

%>