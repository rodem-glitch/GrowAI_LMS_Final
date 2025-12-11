<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(42, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SendAutoDao sendAuto = new SendAutoDao();
CourseAutoDao courseAuto = new CourseAutoDao();

DataSet list = courseAuto.query(
    "SELECT a.*, b.* " +
    " FROM " + courseAuto.table + " a "
    + " INNER JOIN " + sendAuto.table + " b ON a.auto_id = b.id AND b.site_id = " + siteId + " AND b.status = 1 "
    + " WHERE a.site_id = " + siteId + " AND a.course_id = " + courseId
    + " ORDER BY a.auto_id ASC "
);

while(list.next()) {
    list.put("subject_conv", m.cutString(list.s("subject"), 50));
    list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));

    list.put("status_conv", m.getItem(list.s("status"), sendAuto.statusList));
    list.put("homework_conv", m.getItem(list.s("homework_yn"), sendAuto.atypes));
    list.put("exam_conv", m.getItem(list.s("exam_yn"), sendAuto.atypes));
    list.put("std_type_conv", m.getItem(list.s("std_type"), sendAuto.stypes));

    list.put("min_ratio_conv", m.nf(list.d("min_ratio"),0));
    list.put("max_ratio_conv", m.nf(list.d("max_ratio"),0));

    String sendDate = "S".equals(list.s("std_type")) ? cinfo.s("study_sdate") : ("E".equals(list.s("std_type")) ? cinfo.s("study_edate") : "") + "000000";
    if(list.i("std_day") != 0) sendDate = m.addDate("D", list.i("std_day"), sendDate, "yyyyMMdd");

    list.put("send_date", sendDate);
    list.put("send_date_conv", !"".equals(sendDate) ? m.time("yyyy.MM.dd", sendDate) : "-");
}

//출력
p.setBody("management.course_auto");
p.setVar("p_title", "학습독려");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("auto", "current");

p.setLoop("list", list);

p.display();

%>