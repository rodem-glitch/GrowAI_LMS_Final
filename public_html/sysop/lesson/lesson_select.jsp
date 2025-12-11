<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

int cid = m.ri("cid");
int sid = m.ri("sid");
if(0 == cid || 0 == sid) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
CourseLessonDao cl = new CourseLessonDao();
LessonDao lesson = new LessonDao();

//정보
DataSet cinfo = course.find("id = " + cid);
if(!cinfo.next()) { m.jsErrClose("과정정보를 찾을 수 없습니다."); return; }

//추가
if(m.isPost()) {
	if(f.getArr("idx") != null) {

		for(int i=0, max=f.getArr("idx").length; i<max; i++) {
			String[] tmpValue = m.split("|", f.getArr("idx")[i], 2);

			cl.item("id", cl.getSequence());
			cl.item("course_id", cid);
			cl.item("lesson_id", tmpValue[1]);
			cl.item("site_id", siteId);
			cl.item("step_id", sid);
			cl.item("chapter", cl.getOneInt("SELECT MAX(chapter) FROM " + cl.table + " WHERE course_id = " + cid + " AND step_id = " + sid) + 1);
			cl.item("status", 1);
			if(!cl.insert()) {	}

		}
	}
	out.print("<script>try { parent.opener.location.reload(); } catch(e) { } parent.location.reload();</script>");
	return;
}

//폼체크
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_type", null, null);

//목록
ListManager lm = new ListManager();
//lm.setDebug(out);
lm.setRequest(request);
lm.setListNum(15);
lm.setTable(lesson.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteinfo.i("id"));
lm.addWhere("NOT EXISTS (SELECT id FROM " + cl.table + " WHERE course_id = " + cid + " AND step_id = " + sid + " AND lesson_id = a.id)");
lm.addWhere("a.lesson_type != '" + ("W".equals(siteinfo.s("ovp_vendor")) ? "05" : "01") + "'");
lm.addSearch("a.lesson_type", f.get("s_type"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.lesson_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), "W".equals(siteinfo.s("ovp_vendor")) ? lesson.lessonTypes : lesson.catenoidLessonTypes));
	list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm"), 50));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), lesson.statusList));
}

//출력
p.setLayout("pop");
p.setVar("p_title", "차시추가");
p.setBody("lesson.lesson_select");
p.setVar("list_query", m.qs("id, type"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(lesson.statusList));
p.setLoop("lesson_types", m.arr2loop("W".equals(siteinfo.s("ovp_vendor")) ? lesson.lessonTypes : lesson.catenoidLessonTypes));
p.setVar("lesson_cnt", cl.findCount("course_id = " + cid + " AND step_id = " + sid));

p.display();

%>