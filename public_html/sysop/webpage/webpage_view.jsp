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
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("status_conv", m.getItem(info.s("status"), webpage.statusList));

//출력
p.setLayout(ch);
p.setBody("webpage.webpage_view");
p.setVar("p_title", "페이지관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,mode"));
p.setVar("mode_query", m.qs("mode"));

p.setVar(info);

p.display();

%>