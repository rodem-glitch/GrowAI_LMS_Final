<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(928, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }
if(!"malgn".equals(loginId)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SiteConfigDao siteConfig = new SiteConfigDao();

//등록
if(m.isPost() && f.validate()) {

     siteConfig.item("site_id", siteId);
     siteConfig.item("`key`", f.get("key"));
     siteConfig.item("data", f.get("data"));
     siteConfig.item("`desc`", f.get("desc"));
     siteConfig.item("edit_yn", "N");

     if(siteConfig.insert()){
         m.jsAlert("사이트설정을 등록하는 중 오류가 발생했습니다.");
         return;
     }

    //캐시
    siteConfig.remove(siteId + "");

    m.jsAlert("등록하였습니다.");
    m.jsReplace("site_config.jsp?" + m.qs(), "parent");

}

//출력
p.setLayout("poplayer");
p.setBody("site.site_config_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("is_master", "malgn".equals(loginId));

p.display();

%>