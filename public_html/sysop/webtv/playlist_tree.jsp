<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(927, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//폼입력
String cid = m.rs("cid");

//객체
LmCategoryDao category = new LmCategoryDao("webtv_playlist");

//목록
DataSet list = category.find("status = 1 AND module = 'webtv_playlist' AND site_id = " + siteId + "", "*", "parent_id ASC, sort ASC");

//출력
p.setLayout("blank");
p.setBody("webtv.playlist_tree");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setLoop("list", list);
p.setVar("cid", cid);
p.display();

%>