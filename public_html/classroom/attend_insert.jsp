<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//로그인
if(1 > userId) {
    if(m.isMobile()) auth.loginURL = "/mobile/login.jsp";
    auth.loginForm();
    return;
}

//기본키
int cid = m.ri("cid");
if(1 > cid) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

//정보
//courseUser.d(out);
DataSet cuinfo = courseUser.query(
    " SELECT a.id, a.start_date, a.end_date, c.restudy_yn, c.restudy_day "
    + " FROM " + courseUser.table + " a "
    + " INNER JOIN " + course.table + " c ON c.id = a.course_id AND c.status != -1 AND c.site_id = " + siteId
    + " WHERE a.course_id = ? AND a.user_id = " + userId + " AND a.status IN (1, 3) AND a.start_date <= '" + sysToday + "' AND a.end_date >= '" + sysToday + "' "
    + " ORDER BY a.id DESC "
    , new Integer[] {cid}
    , 1
);
if(!cuinfo.next()) { m.jsError(_message.get("alert.course_user.nodata")); return; }

//이동
m.redirect("../classroom/viewer.jsp?cuid=" + cuinfo.s("id") + "&" + m.qs("cid"));

%>