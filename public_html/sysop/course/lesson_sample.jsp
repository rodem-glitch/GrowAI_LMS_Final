<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
LessonDao lesson = new LessonDao();

//폼체크
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(lesson.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("a.onoff_type = 'N'");
lm.addWhere("W".equals(siteinfo.s("ovp_vendor")) ? " a.lesson_type != '05'" : "a.lesson_type != '01'");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.lesson_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), "W".equals(siteinfo.s("ovp_vendor")) ? lesson.types : lesson.catenoidTypes));
	list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm"), 50));
	list.put("lesson_nm_conv2", m.addSlashes(list.s("lesson_nm")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), lesson.statusList));
}

//출력
p.setLayout("pop");
p.setBody("course.lesson_sample");
p.setVar("p_title", "샘플강의");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id, type"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(lesson.statusList));
p.display();

%>