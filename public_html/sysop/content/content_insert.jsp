<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(29, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
ContentDao content = new ContentDao();
UserDao user = new UserDao();

//폼체크
f.addElement("content_nm", null, "hname:'콘텐츠명', required:'Y'");
f.addElement("description", null, "hname:'설명', allowhtml:'Y'");
f.addElement("status", 1, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	int newId = content.getSequence();
	content.item("id", newId);
	content.item("site_id", siteId);
	content.item("category_id", 0);
	content.item("content_nm", f.get("content_nm"));
	content.item("description", f.get("description"));
	content.item("manager_id", userId);
	content.item("reg_date", m.time("yyyyMMddHHmmss"));
	content.item("status", f.getInt("status"));

	if(!content.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	String path = dataDir + "/Contents/" + newId;
	File dfd = new File(path);
	if(!dfd.exists()) { dfd.mkdirs(); };

	if(dfd.exists()) {
		try {
			String cmd = "chmod 777 " + path;
			Runtime.getRuntime().exec(cmd);
		}
		catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); return; }
		catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); return; }
	}

	m.jsReplace("lesson_list.jsp?cid=" + newId, "parent");
	return;
}

//출력
p.setBody("content.content_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("status_list", m.arr2loop(content.statusList));
p.setLoop("managers", user.getManagers(siteId));
p.display();

%>