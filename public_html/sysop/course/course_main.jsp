<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
Menu.accessible(102, userId, userKind);

//객체
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");
CourseMainDao courseMain = new CourseMainDao();

//목록-타입
String types[] = m.split("|", SiteConfig.s("main_course_types"));
DataSet tlist = new DataSet();
tlist = m.arr2loop(types);
tlist.sort("name", "asc");
if(!tlist.next() || (2 > tlist.size() && "".equals(tlist.s("id")))) {
	SiteConfig.put("main_course_types", m.join("|", courseMain.defaultTypes));
	m.jsAlert("진열영역 설정에 문제가 있어 초기설정으로 초기화됩니다.");
	m.jsReplace("course_main.jsp");
}

//폼입력
String type = m.rs("type", tlist.s("id"));
String mode = m.rs("mode");

//폼체크
f.addElement("type", type, null);

if("add".equals(mode)) {

	if(0 == courseMain.findCount("site_id = " + siteId + " AND type = '" + type + "' AND course_id = " + m.ri("cid"))) {
		if(0 == course.findCount(
			" id = " + m.ri("cid") + " AND site_id = " + siteId + " AND status != -1 "
			+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
		)) {
			m.jsError("해당 과정정보가 없습니다.");
			return;
		}
		courseMain.item("site_id", siteId);
		courseMain.item("type", type);
		courseMain.item("course_id", m.ri("cid"));
		courseMain.item("sort", courseMain.getLastSort(siteId, type));
		if(!courseMain.insert()) {
			m.jsError("과정을 등록하는 중 오류가 발생했습니다.");
			return;
		}
	}

	m.redirect("course_main.jsp?type=" + type + "&" + m.qs("id,mode,type"));
	return;

} else if("del".equals(mode)) {
	if(0 == course.findCount(
		" id = " + m.ri("id") + " AND site_id = " + siteId + " AND status != -1 "
		+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
	)) {
		m.jsError("해당 과정정보가 없습니다.");
		return;
	}

	courseMain.delete("site_id = " + siteId + " AND type = '" + type + "' AND course_id = " + m.ri("id"));
	m.redirect("course_main.jsp?type=" + type + "&" + m.qs("id,mode,type"));
	return;

} else if("sort".equals(mode)) {

	String[] idx = m.reqArr("idx");
	if(idx == null) {
		m.jsError("해당 과정정보가 없습니다.");
		return;
	}

	for(int i=0; i<idx.length; i++) {
		courseMain.item("sort", i);
		courseMain.update("site_id = " + siteId + " AND type = '" + type + "' AND course_id = " + idx[i]);
	}
	m.redirect("course_main.jsp?type=" + type + "&" + m.qs("id,mode,type"));
	return;
}

//카테고리
DataSet categories = category.getList(siteId);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
//lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setListNum(20000);
lm.setTable(courseMain.table + " m JOIN " + course.table + " a ON a.id = m.course_id");
lm.setFields("a.*, m.sort" + ("C".equals(userKind) ? ", IF(a.id IN (" + manageCourses + "), 'Y', 'N') delete_yn" : ""));
lm.addWhere("a.status != -1");
lm.addWhere("m.site_id = " + siteId + " AND m.type = '" + type + "'");
lm.setOrderBy("m.sort ASC");
//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 40));
	list.put("status_conv", m.getItem(list.s("status"), course.statusList));
	list.put("display_conv", list.b("display_yn") ? "정상" : "숨김");

	list.put("price_conv", m.nf(list.i("price")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("course_file_url", !"".equals(list.s("course_file")) ? siteDomain + m.getUploadUrl(list.s("course_file")) : "");
	list.put("cate_name", category.getTreeNames(list.i("category_id")));
	list.put("type_conv", m.getItem(list.s("course_type"), course.types));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffPackageTypes));

	list.put("alltimes_block", "A".equals(list.s("course_type")));
	list.put("request_sdate_conv", m.time("yyyy.MM.dd", list.s("request_sdate")));
	list.put("request_edate_conv", m.time("yyyy.MM.dd", list.s("request_edate")));
	list.put("study_sdate_conv", m.time("yyyy.MM.dd", list.s("study_sdate")));
	list.put("study_edate_conv", m.time("yyyy.MM.dd", list.s("study_edate")));

	list.put("delete_block", (!adminBlock ? list.b("delete_yn") : true));
}

//출력
if("pop".equals(m.rs("mode2"))) p.setLayout("poplayer");
p.setBody("course.course_main");
p.setVar("form_script", f.getScript());
p.setVar("list_query", m.qs("id"));
p.setVar("type_query", m.qs("id,type"));
p.setVar("query", m.qs());

p.setVar("type", type);
p.setLoop("list", list);

p.setLoop("type_list", tlist);
p.display();

%>
