<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int cid = m.ri("cid");
if(cid == 0) { m.jsAlert("기본키는 반드시 지정되어야 합니다."); return; }

//변수
String idx = m.rs("idx");
boolean isAll = "".equals(idx);

CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseRenewDao courseRenew = new CourseRenewDao();
UserDao user = new UserDao();

//폼체크
f.addElement("send_list", null, "hname:'변경대상'");
f.addElement("mod_type", null, "hname:'변경유형', required:'Y'");
f.addElement("date_modify", 1, "hname:'변경일수', required:'Y', min:'1', max:'365', option:'number'");

if(m.isPost() && f.validate()) {

    String[] cuserArr = idx.split(",");
    DataSet list = courseUser.query(
        "SELECT a.*, u.id uid"
            + " FROM " + courseUser.table + " a "
            + " INNER JOIN " + course.table + " c ON a.course_id = c.id "
            + " INNER JOIN " + user.table + " u ON a.user_id = u.id "
            + " WHERE c.id = " + cid + ""
            + " AND u.status != -1"
            + (!isAll ? " AND a.id IN (" + m.join(",", cuserArr) + ") " : "")
    );

    if(!list.next()) {
        m.jsAlert("해당 수강생정보가 없습니다.");
        m.js("parent.CloseLayer();");
        return;
    }

    list.first();
    String now = m.time("yyyyMMddHHmmss");
    while(list.next()) {
        courseUser.clear();
        courseRenew.clear();

        int modDate =  1 > f.getInt("mod_type") ? -1 * f.getInt("date_modify") : f.getInt("date_modify");
        String newEndDate = m.addDate("D", modDate, list.s("end_date"), "yyyyMMdd");

        if(0 > m.diffDate("D", list.s("start_date"), newEndDate)) newEndDate = list.s("start_date");
        courseUser.item("end_date", newEndDate);
        courseUser.item("mod_date", now);

        if(!courseUser.update("id = " + list.i("id") + "")) { }
        courseRenew.item("site_id", siteId);
        courseRenew.item("course_user_id", list.s("id"));
        courseRenew.item("renew_type", "S");
        courseRenew.item("start_date", list.s("start_date"));
        courseRenew.item("end_date", newEndDate);
        courseRenew.item("user_id", userId);
        courseRenew.item("order_item_id", -99);
        courseRenew.item("reg_date", now);
        courseRenew.item("status", 1);
        if(!courseRenew.insert()) { }
    }
    m.jsAlert("수정되었습니다.");
    m.js("parent.location.href = parent.location.href;");
    return;
}

String[] cuserArr = idx.split(",");
DataSet users = courseUser.query(
    "SELECT a.*, u.id uid, u.user_nm, u.login_id"
        + " FROM " + courseUser.table + " a "
        + " INNER JOIN " + course.table + " c ON a.course_id = c.id "
        + " INNER JOIN " + user.table + " u ON a.user_id = u.id "
        + " WHERE c.id = " + cid + ""
        + " AND u.status != -1"
        + (!isAll ? " AND a.id IN (" + m.join(",", cuserArr) + ")" : "")
);

if(!users.next()) {
    m.jsAlert("해당 수강생정보가 없습니다.");
    m.js("parent.CloseLayer();");
    return;
}

users.first();
while(users.next()) {
    users.put("start_date_conv", m.time("yyyy.MM.dd", users.s("start_date")));
    users.put("end_date_conv", m.time("yyyy.MM.dd", users.s("end_date")));
}


//출력
p.setLayout("poplayer");
p.setBody("course.pop_sdate_modify");
p.setVar("p_title", "학습기간일괄수정");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("users", users);

p.setVar("all_block", isAll);
p.display();
%>