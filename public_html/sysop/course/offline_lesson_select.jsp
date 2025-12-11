<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(129, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
LessonDao lesson = new LessonDao();
UserDeptDao userDept = new UserDeptDao();

//정보
DataSet types = m.arr2loop(lesson.offlineTypes);

//폼체크
f.addElement("s_type", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(30);
lm.setTable(lesson.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status = 1");
lm.addWhere("a.use_yn = 'Y'");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("a.onoff_type = 'F'");
lm.addSearch("a.lesson_type", f.get("s_type"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.lesson_nm", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id desc");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), lesson.allTypes));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm"), 90));
	list.put("lesson_nm_conv2", m.addSlashes(list.s("lesson_nm")));
}

//출력
p.setLayout("pop");
p.setBody("course.offline_lesson_select");
p.setVar("p_title", "강의선택");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("types", types);
p.display();

%>