<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(928, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SiteConfigDao siteConfig = new SiteConfigDao();

//사이트설정
boolean isEditable = false;
DataSet list = siteConfig.find("site_id = " + siteId, "*", "edit_yn ASC, `key` ASC");

while(list.next()) {
	if(list.b("edit_yn")) isEditable = true;
	list.put("data", Malgn.htt(list.s("data")));
}

//수정
if(m.isPost() && f.validate() && isEditable) {

	int failed = 0;
	siteConfig.d(out);
	if(null != f.getArr("key")) {
		for(int i = 0; i < f.getArr("key").length; i++) {
			siteConfig.item("data", f.getArr("data")[i]);
			if(!siteConfig.update("`key` = '" + f.getArr("key")[i] + "' AND site_id = " + siteId + " AND edit_yn = 'Y'")) { failed++; }
		}
	}

	//캐시
	siteConfig.remove(siteId + "");

	//이동
	if(0 < failed) {
		m.jsAlert("사이트설정을 수정하는 중 오류가 발생했습니다.");
	} else {
		m.jsReplace("site_config.jsp?" + m.qs(), "parent");
	}
	return;
}

//출력
p.setBody("site.site_config");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("is_editable", isEditable);
p.setVar("is_master", "malgn".equals(loginId));

p.display();

%>