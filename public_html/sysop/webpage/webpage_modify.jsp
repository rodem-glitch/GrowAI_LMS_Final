<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(127, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
WebpageDao webpage = new WebpageDao();
FileDao file = new FileDao();
SiteDao site = new SiteDao();

//정보
DataSet info = webpage.find("id = " + id + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//파일
String pageDir = tplRoot + "/page";
File pdir = new File(pageDir);
if(!pdir.exists()) pdir.mkdirs();


//페이지
String content = m.readFile(pageDir + "/" + info.s("code") + ".html");
if(!"".equals(content)) info.put("content", content);
info.put("content_save", m.htt(info.s("content_save")));

//폼체크
f.addElement("code", info.s("code"), "hname:'코드', required:'Y'");
f.addElement("breadcrumb", info.s("breadcrumb"), "hname:'분류명'");
f.addElement("webpage_nm", info.s("webpage_nm"), "hname:'페이지명', required:'Y'");
f.addElement("content", null, "hname:'내용', allowscript:'Y', allowhtml:'Y', allowiframe:'Y'");
f.addElement("layout", info.s("layout"), "hname:'레이아웃', required:'Y'");
f.addElement("status", info.i("status"), "hname:' 상태', required:'Y', option:'number'");

//등록
if(m.isPost() && f.validate()) {

	//변수
	String code = f.get("code").toLowerCase();
	String pagePath = pageDir + "/" + code + ".html";

	//제한
	if(m.inArray(code, webpage.exceptions)) { m.jsAlert("사용할 수 없는 코드입니다."); return; }

	//제한
	if(!info.s("code").equals(code)
		&& 0 < webpage.findCount("code = '" + code + "' AND site_id = " + siteId + "  AND status != -1 AND id != " + id + "")) {
		m.jsAlert("이미 해당 코드를 사용중입니다."); return;
	}

	webpage.item("code", code);
	webpage.item("breadcrumb", f.get("breadcrumb"));
	webpage.item("webpage_nm", f.get("webpage_nm"));
	if("publish".equals(m.rs("mode"))) webpage.item("content", f.get("content"));
	webpage.item("content_save", f.get("content"));
	webpage.item("layout", f.get("layout"));
	webpage.item("status", f.getInt("status"));
	if(!webpage.update("id = " + id + "")) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	//이동
	if("publish".equals(m.rs("mode"))) m.jsReplace("webpage_list.jsp?" + m.qs("id,mode"), "parent");
	else m.js("parent.preview('" + m.rs("mode") + "');");
	return;
}

//출력
p.setLayout(ch);
p.setBody("webpage.webpage_insert");
p.setVar("p_title", "페이지관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setLoop("status_list", m.arr2loop(webpage.statusList));
p.setLoop("layouts", webpage.getLayouts(siteinfo.s("doc_root") + "/html/layout"));
//p.setLoop("templates", webpage.getLayouts(siteinfo.s("doc_root") + "/html/layout", "webpage"));
p.display();

%>