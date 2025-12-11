<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(29, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }
if(id == -999) { m.redirect("lesson_list.jsp?cid="+id); return; }

//객체
ContentDao content = new ContentDao();
UserDao user = new UserDao();

//정보
DataSet info = content.query(
	" SELECT a.*, u.user_nm manager_name "
	+ " FROM " + content.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
	+ " WHERE a.id = " + id + " AND a.status != -1 AND a.site_id = " + siteId + " "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//폼체크
f.addElement("content_nm", info.s("content_nm"), "hname:'콘텐츠명', required:'Y'");
if(!courseManagerBlock) f.addElement("manager_id", info.s("manager_id"), "hname:'담당자'");
if(!courseManagerBlock) f.addElement("manager_name", info.s("manager_name"), "hname:'담당자'");
f.addElement("status", info.i("status"), "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	content.item("content_nm", f.get("content_nm"));
	content.item("description", f.get("description"));
	if(!courseManagerBlock) content.item("manager_id", f.getInt("manager_id"));
	content.item("status", f.getInt("status"));

	if(!content.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	File dfd = new File(dataDir + "/Contents/" + id);
	if(!dfd.exists()) { dfd.mkdirs(); };

	m.jsReplace("content_list.jsp?" + m.qs("id"), "parent");
	return;
}

info.put("description", m.htt(info.s("description")));

//출력
p.setBody("content.content_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setLoop("status_list", m.arr2loop(content.statusList));
p.setLoop("managers", user.getManagers(siteId));

p.display();

%>