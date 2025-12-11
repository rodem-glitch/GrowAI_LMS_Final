<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

String type = m.rs("type"); // main, right
String mode = m.rs("mode"); // insert, modify
int id = m.ri("id");

//객체
BannerDao banner = new BannerDao();

boolean flag = false;
int sort = 0;
if(id != 0) {
	DataSet info = banner.find("id = " + id);
	if(info.next()) {
		flag = type.equals(info.s("banner_type")) ? false : true;
	}
}

//목록
int maxSort = banner.findCount("site_id = " + siteId + " AND status > -1 AND banner_type = '" + type + "'") + ("insert".equals(mode) ? 1 : (flag ? 1 : 0));
for(int i=1; i<= maxSort; i++) {
	out.print("<option value=\"" + i + "\" " + (maxSort == i ? "selected" : "") + ">" + i + "</option>");
}

%>