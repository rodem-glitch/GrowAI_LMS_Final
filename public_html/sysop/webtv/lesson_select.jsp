<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(123, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
WebtvDao webtv = new WebtvDao();
ContentDao content = new ContentDao();
LessonDao lesson = new LessonDao();

//정보
String type = "";
DataSet types = m.arr2loop("W".equals(siteinfo.s("ovp_vendor")) ? lesson.lessonTypes : lesson.catenoidLessonTypes);

//폼체크
f.addElement("s_content", null, null);
f.addElement("s_type", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(15);
lm.setTable(lesson.table + " a LEFT JOIN " + content.table + " c ON c.id = a.content_id AND c.status = 1");
lm.setFields("a.*, c.content_nm");
lm.addWhere("a.status = 1");
lm.addWhere("a.use_yn = 'Y'");
lm.addWhere("a.site_id = " + siteId + "");
//lm.addWhere("a.lesson_type != '" + ("W".equals(siteinfo.s("ovp_vendor")) ? "05" : "01") + "'");
lm.addSearch("a.content_id", f.get("s_content"));
lm.addSearch("a.lesson_type", f.get("s_type"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.lesson_nm, a.author, a.start_url, c.content_nm", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.content_id desc, a.sort asc, a.id desc");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	//list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), "W".equals(siteinfo.s("ovp_vendor")) ? lesson.types : lesson.catenoidTypes));
	list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), lesson.allTypes));
	list.put("moblie_block", !"".equals(list.s("mobile_a")) || !"".equals(list.s("mobile_i")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("total_time_conv", m.nf(list.i("total_time")));
	list.put("content_nm_conv", m.cutString(list.s("content_nm"), 34));
	list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm"), 34));
	list.put("lesson_nm_conv2", m.addSlashes(list.s("lesson_nm")));
}

//출력
p.setLayout("pop");
p.setBody("webtv.lesson_select");
p.setVar("p_title", "강의선택");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("content_list", content.find("status != -1 AND site_id = " + siteId + "", "*", "content_nm ASC"));
p.setLoop("types", types);
p.display();

%>