<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(127, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
WebpageDao webpage = new WebpageDao();
FileDao file = new FileDao();
SiteDao site = new SiteDao();

//파일
String pageDir = tplRoot + "/page";
File pdir = new File(pageDir);
if(!pdir.exists()) pdir.mkdirs();


//폼체크
f.addElement("code", null, "hname:'코드', required:'Y'");
f.addElement("breadcrumb", "소개", "hname:'분류명'");
f.addElement("webpage_nm", null, "hname:'페이지명', required:'Y'");
//f.addElement("title", null, "hname:'타이틀', required:'Y'");
f.addElement("content", null, "hname:'내용', allowscript:'Y', allowhtml:'Y', allowiframe:'Y'");
f.addElement("layout", null, "hname:'레이아웃', required:'Y'");
//f.addElement("template", null, "hname:'템플릿', required:'Y'");
f.addElement("status", 1, "hname:' 상태', required:'Y', option:'number'");

//등록
if(m.isPost() && f.validate()) {

	String code = f.get("code").toLowerCase();

	//제한
	if(m.inArray(code, webpage.exceptions)) { m.jsAlert("사용할 수 없는 코드입니다."); return; }

	//제한
	if(0 < webpage.findCount("code = '" + code + "' AND site_id = " + siteId + " AND status != -1")) {
		m.jsAlert("이미 해당 코드를 사용중입니다."); return;
	}

	int newId = webpage.getSequence();
	webpage.item("id", newId);
	webpage.item("site_id", siteId);
	webpage.item("code", code);
	webpage.item("breadcrumb", f.get("breadcrumb"));
	webpage.item("webpage_nm", f.get("webpage_nm"));
//	webpage.item("title", f.get("title"));
	webpage.item("content", f.get("content"));
	webpage.item("content_save", f.get("content"));
	webpage.item("layout", f.get("layout"));
	//webpage.item("template", f.get("template"));
	webpage.item("reg_date", m.time("yyyyMMddHHmmss"));
	webpage.item("status", f.getInt("status"));
//	webpage.item("attach_file", f.getInt("attach_file"));
	if(!webpage.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }
/*
	//작성-파일
	m.writeFile(pageDir + "/" + code + ".html", f.get("content"));
	m.chmod("777", pageDir + "/" + code + ".html");
*/
	//이동
	m.jsReplace("webpage_list.jsp?" + m.qs(), "parent");
	return;
}

//출력
p.setLayout(ch);
p.setBody("webpage.webpage_insert");
p.setVar("p_title", "페이지관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("status_list", m.arr2loop(webpage.statusList));
p.setLoop("layouts", webpage.getLayouts(siteinfo.s("doc_root") + "/html/layout"));
//p.setLoop("templates", webpage.getLayouts(siteinfo.s("doc_root") + "/html/layout", "webpage"));
p.display();

%>