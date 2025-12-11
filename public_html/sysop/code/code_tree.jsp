<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(3, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CodeDao code = new CodeDao();

//목록
DataSet list = code.query(
	"SELECT * "
	+ " FROM " + code.table + " a"
	+ " WHERE a.code IS NOT NULL AND a.site_id = " + siteId + " "
	+ " ORDER BY a.parent_id ASC, a.sort ASC "
);
while(list.next()) {
	list.put("code_nm_conv", m.cutString(list.s("code_nm"), 20));
}

//출력
p.setLayout("blank");
p.setBody("code.code_tree");
p.setVar("p_title", "통합코드");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setLoop("list", list);
p.display();

%>