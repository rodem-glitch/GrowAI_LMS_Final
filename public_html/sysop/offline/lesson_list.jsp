<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(88, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
LessonDao lesson = new LessonDao();

//폼체크
f.addElement("s_type", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : f.getInt("s_listnum", 20));
lm.setTable(lesson.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("a.onoff_type = 'F'"); //오프라인
if(courseManagerBlock) lm.addWhere("a.manager_id IN (-99, " + userId + ")");
lm.addSearch("a.status", f.get("s_status"));
lm.addSearch("a.lesson_type", f.get("s_type"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.lesson_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), lesson.offlineTypes));
	list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm"), 100));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), lesson.statusList));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "집합강의관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>아이디", "lesson_nm=>강의명", "lesson_type_conv=>구분", "lesson_hour=>기본수업시수", "description=>설명", "reg_date_conv=>등록일", "status_conv=>상태" }, "집합강의관리(" + m.time("yyyy-MM-dd"));
	ex.write();
	return;
}

//출력
p.setBody("offline.lesson_list");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(lesson.statusList));
p.setLoop("types", m.arr2loop(lesson.offlineTypes));
p.display();

%>