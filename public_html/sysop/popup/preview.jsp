<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(7, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다"); return; }

//객체
PopupDao popup = new PopupDao();

DataSet info = popup.find("id = " + id);
if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

info.put("height_conv", info.i("height") > 30 ? info.i("height") - 30 : 30);
info.put("width_conv", info.i("width") > 150 ? info.i("width") - 50 : 150);

//출력
p.setVar(info);

if("Y".equals(info.s("template_yn")) && !"".equals(info.s("layout"))) {
	p.setRoot(docRoot + "/html");
	p.setLayout("blank");
	p.setBody("pop_template." + info.s("layout"));
	p.display();
	//p.print(out, docRoot + "/html/pop_template/" + info.s("layout") + ".html");
} else {
	p.setLayout("blank");
	p.setBody("popup.preview");
	p.setVar("site_domain" , siteDomain);
	p.display();
}


%>