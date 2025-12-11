<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
//if(!Menu.accessible(79, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//폼입력
String mode = m.rs("mode");

//객체
SubjectDao subject = new SubjectDao();
CourseDao course = new CourseDao();

//폼체크
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(subject.table + " a");
lm.setFields(
	"a.* "
	+ ", (SELECT COUNT(*) FROM " + course.table + " WHERE subject_id = a.id AND status != -1) course_cnt "
);
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.course_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), subject.statusList));
	list.put("course_cnt_conv", m.nf(list.i("course_cnt")));
}

//출력
p.setLayout("pop");
p.setBody("course.subject_select");
p.setVar("p_title", "과정명 선택");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar(mode + "_block", true);
p.display();

%>