<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseRenewDao courseRenew = new CourseRenewDao();

//변수
boolean isReal = true;
int sid = 50;
int ctid = 5289;
//int sid = 1;
//int ctid = 55;
String endDate = "20200710";

//정보-과정
course.d(out);
DataSet clist = course.find("site_id = " + sid + " AND category_id = " + ctid + " AND status != -1");
out.println("[과정 " + clist.size() + "개 검색됨]<br>");
String[] carr = new String[clist.size()];
String cidx = "";
while(clist.next()) {
    carr[clist.getIndex()] = clist.s("id");
}
cidx = m.join(",", carr);

//수정-과정
course.item("study_edate", endDate);
if(isReal && course.update("site_id = " + sid + " AND category_id = " + ctid + " AND status != -1")) {
    out.println("과정 학습기간 수정성공<br>");
} else {
    out.println("과정 학습기간 수정실패😰<br>");
}

//정보-수강생
courseUser.d(out);
DataSet culist = courseUser.find("site_id = " + sid + " AND course_id IN (" + cidx + ") AND status != -1");
out.println("[수강생 " + culist.size() + "명 검색됨]<br>");

//수정-수강생
courseUser.item("end_date", endDate);
if(isReal && courseUser.update("site_id = " + sid + " AND course_id IN (" + cidx + ") AND status != -1")) {
    out.println("수강생 학습기간 수정성공<br>");
} else {
    out.println("수강생 학습기간 수정실패😰<br>");
}

//등록-갱신
courseRenew.d(out);
courseRenew.item("site_id", sid);
courseRenew.item("renew_type", "U");
courseRenew.item("end_date", endDate);
courseRenew.item("user_id", "277437");
courseRenew.item("order_item_id", "-99");
courseRenew.item("reg_date", m.time("yyyyMMddHHmmss"));
courseRenew.item("status", "1");
while(culist.next()) {
    out.print(culist.getIndex() + ". " + culist.s("id") + " / 기존수강기간 : " + culist.s("start_date") + " ~ " + culist.s("end_date"));

    courseRenew.item("course_user_id", culist.s("id"));
    courseRenew.item("start_date", culist.s("start_date"));
    if(isReal && !endDate.equals(culist.s("end_date")) && courseRenew.insert()) {
        out.println(" / 기록성공<br>");
    } else {
        out.println(" / 기록실패😰<br>");
    }
}
/*
CourseUserLogDao courseUserLog = new CourseUserLogDao();

ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(1000000);
lm.setTable(courseUserLog.table + " a");
lm.setFields("a.id, a.user_agent");
lm.addWhere("a.id > 10305466");
lm.addWhere("a.id < 10837990");
lm.setOrderBy("a.id asc");

out.println("<a href=\"biztest.jsp?page=" + (m.parseInt(m.rs("page")) + 1) + "\">=> 다음쪽</a><br><div style=\"color:gray; font-size:10px;\">");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	String normalized = courseUserLog.getBrowser(list.s("user_agent"));
	if("unknown".equals(normalized) || list.s("user_agent").equals(normalized)) {
		//out.println("＝＝" + list.s("id"));
		continue;
	}

	courseUserLog.item("user_agent", normalized);
	if(!courseUserLog.update("id = " + list.s("id"))) out.println("<br><span style=\"color:red; font-size:13px;\">■■ " + list.s("id") + "</span><br>");
	//if(!courseUserLog.update("id = " + list.s("id"))) out.println("<br><span style=\"color:red; font-size:13px;\">■■ " + list.s("id") + "</span><br>");
	//else out.println("<span style=\"color:#00ff00;\">○○ " + list.s("id") + "</span>");
}

out.println("<div style=\"font-size:20px;\">최종 ID : " + list.s("id") + "</div>");
out.println("</div><a href=\"biztest.jsp?page=" + (m.parseInt(m.rs("page")) + 1) + "\">=> 다음쪽</a>");
*/
%>