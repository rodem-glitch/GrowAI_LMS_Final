<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(125, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String code = m.rs("code");
if("".equals(code)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
SitemapDao sitemap = new SitemapDao(siteId);

//정보
DataSet info = sitemap.find("site_id = " + siteId + " AND code = '" + code + "'");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//검사-기본메뉴
if(info.b("default_yn")) { m.jsError("기본 메뉴는 삭제가 불가합니다.\\n중지 상태로 변경해주세요."); return; }

//검사-하위메뉴
if(sitemap.findCount("site_id = " + siteId + " AND parent_cd = '" + code + "'") > 0) { m.jsError("하위메뉴가 존재합니다.\\n하위메뉴부터 삭제해주세요."); return; }

//삭제
//sitemap.item("status", -1);
//if(!sitemap.update("site_id = " + siteId + " AND code = '" + code + "'")) {
if(!sitemap.delete("site_id = " + siteId + " AND code = '" + code + "'")) {
	m.jsError("삭제하는 중 오류가 발생했습니다.");
	return;
}

out.print("<script>parent.left.location.reload();</script>");
m.jsReplace("sitemap_insert.jsp");

%>