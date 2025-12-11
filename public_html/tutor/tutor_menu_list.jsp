<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
int lnb = m.ri("lnb");
int depth = m.ri("depth", 1);
String displayYn = m.rs("display_yn", "Y");
String mode = !"".equals(m.rs("mode")) ? m.rs("mode") : "LNB";
String type = m.rs("type");

//객체
//LmCategoryDao category = new LmCategoryDao("course");
//DataSet rs = category.getSubList(siteId, lnb, depth);
//DataSet rs = category.find("site_id = " + siteId + " AND display_yn = 'Y' AND status = 1 AND module = 'course' AND id > 0 ORDER BY sort", "*");

//객체
UserDao user = new UserDao();
TutorDao tutor = new TutorDao();

//목록
DataSet list = user.query(
	" SELECT a.id, a.user_nm, t.name_en "
	+ " FROM " + user.table + " a "
	+ " INNER JOIN " + tutor.table + " t ON a.id = t.user_id AND t.status = 1 "
	+ " WHERE a.site_id = " + siteId + " AND a.tutor_yn = 'Y' AND a.display_yn = 'Y' AND a.status = 1 "
	+ " ORDER BY a.user_nm ASC "
);
while(list.next()) {
	out.println("<li id=\"" + mode + "_TUTOR_"+ list.s("id") +"\"" + ("half".equals(type) ? " class=\"half\"" : "") + "><a href=\"/tutor/tutor_view.jsp?id="+ list.s("id") +"\" title=\""+ list.s("user_nm")	+" 소개페이지로 이동\">"+ list.s("user_nm") +"</a></li>");
	if("half".equals(type) && list.b("__last") && (list.i("__ord") % 2 == 1)) out.println("<li id=\"" + mode + "_TUTOR_DUMMY\" class=\"half\">&nbsp;</li>");
}

%>