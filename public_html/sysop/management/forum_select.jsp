<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
ForumDao forum = new ForumDao();
CourseModuleDao courseModule = new CourseModuleDao();
LmCategoryDao category = new LmCategoryDao();

//처리
if("add".equals(m.rs("mode"))) {
	//기본키
	int id = m.ri("id");
	if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	//정보
	DataSet info = forum.find("id = " + id + " AND status = 1 AND site_id = " + siteId + "");
	if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

	//제한
	if(0 < courseModule.findCount("course_id = " + courseId + " AND module = 'forum' AND module_id = " + id + " AND status != -1")) {
		m.jsAlert("해당 토론은 이미 배정되어 있습니다.");
		m.js("opener.location.href = opener.location.href; window.close();");
		return;
	}

	String applyType = "R".equals(cinfo.s("course_type")) ? "1" : "2";
	int chapter = "R".equals(cinfo.s("course_type")) ? 1 : 0;
	int totalAssignScore = courseModule.getOneInt(
		"SELECT SUM(assign_score) FROM " + courseModule.table + " "
		+ " WHERE course_id = " + courseId + " AND module = 'forum' AND status = 1 "
	);
	int assignScore = cinfo.i("assign_forum") - totalAssignScore;
	if(assignScore < 0) assignScore = 0;

	//추가
	courseModule.item("course_id", courseId);
	courseModule.item("site_id", siteId);
	courseModule.item("module", "forum");
	courseModule.item("module_id", id);
	courseModule.item("module_nm", info.s("forum_nm"));
	courseModule.item("parent_id", 0);
	courseModule.item("item_type", "R");
	courseModule.item("assign_score", assignScore);
	courseModule.item("apply_type", applyType);
	courseModule.item("start_day", 0);
	courseModule.item("period", 0);
	courseModule.item("chapter", chapter);
	courseModule.item("start_date", "");
	courseModule.item("end_date", "");
	if("1".equals(applyType)) {
		courseModule.item("start_date", cinfo.s("study_sdate") + "000000");
		courseModule.item("end_date", cinfo.s("study_edate") + "000000");
	}
	courseModule.item("status", 1);
	if(!courseModule.insert()) { m.jsError("등록하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsAlert("추가되었습니다.");
	m.js("opener.location.href = opener.location.href; window.close();");
	return;
}

//변수
String subjectId = m.rs("s_category", cinfo.s("category_id"));

//폼체크
f.addElement("s_category", subjectId, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	forum.table + " a "
	
);
lm.setFields("a.*");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("NOT EXISTS ( "
	+ " SELECT 1 FROM " + courseModule.table + " "
	+ " WHERE course_id = " + courseId + " AND module = 'forum' AND module_id = a.id "
+ " )");
if(courseManagerBlock) lm.addWhere("a.manager_id IN (-99, " + userId + ")");
if("N".equals(cinfo.s("onoff_type"))) lm.addWhere("a.onoff_type = '" + cinfo.s("onoff_type") + "'");
lm.addSearch("a.category_id", subjectId);
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.forum_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), forum.onoffTypes));
	list.put("forum_nm_conv", m.cutString(list.s("forum_nm"), 90));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), forum.statusList));
}


//출력
p.setLayout("pop");
p.setBody("management.forum_select");
p.setVar("p_title", "토론 추가");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("course", cinfo);
p.setLoop("categories", category.getList(siteId));
p.display();

%>