<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(104, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");
MCal mcal = new MCal(); mcal.yearRange = 10;

//폼체크
f.addElement("s_req_sdate", null, null);
f.addElement("s_req_edate", null, null);
f.addElement("s_std_sdate", null, null);
f.addElement("s_std_edate", null, null);

f.addElement("s_year", null, null);
f.addElement("s_category", null, null);
f.addElement("s_onofftype", null, null);
f.addElement("s_type", null, null);
f.addElement("s_display", null, null);
//f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//카테고리
DataSet categories = category.getList(siteId);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(course.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addSearch("a.year", f.get("s_year"));
lm.addSearch("a.course_type", f.get("s_type"));
lm.addSearch("a.onoff_type", f.get("s_onofftype"));
//lm.addSearch("a.status", f.get("s_status"));
lm.addSearch("a.display_yn", f.get("s_display"));
if("C".equals(userKind)) lm.addWhere("a.id IN (" + manageCourses + ")");
if(!"".equals(f.get("s_req_sdate"))) lm.addWhere("a.request_edate >= '" + m.time("yyyyMMdd", f.get("s_req_sdate")) + "'");
if(!"".equals(f.get("s_req_edate"))) lm.addWhere("a.request_sdate <= '" + m.time("yyyyMMdd", f.get("s_req_edate")) + "'");
if(!"".equals(f.get("s_std_sdate"))) lm.addWhere("a.study_edate >= '" + m.time("yyyyMMdd", f.get("s_std_sdate")) + "'");
if(!"".equals(f.get("s_std_edate"))) lm.addWhere("a.study_sdate <= '" + m.time("yyyyMMdd", f.get("s_std_edate")) + "'");
if(!"".equals(f.get("s_category"))) {
	lm.addWhere("a.category_id IN ( '" + m.join("','", category.getChildNodes(f.get("s_category"))) + "' )");
}
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.course_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

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
}

//출력
p.setLayout("pop");
p.setBody("course.pop_course_select");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(course.statusList));
p.setLoop("categories", categories);
p.setLoop("onoff_types", m.arr2loop(course.onoffPackageTypes));
p.setLoop("types", m.arr2loop(course.types));
p.setLoop("years", mcal.getYears());
p.setVar("this_year", m.time("yyyy"));
p.display();

%>