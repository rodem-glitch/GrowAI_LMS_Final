<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//기본키
String mode = m.rs("mode");
String form = m.rs("form", "form1");
if("".equals(mode)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//변수
boolean includePackage = "main".equals(mode) || "crm_course".equals(mode);

//객체
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");
MCal mcal = new MCal(); mcal.yearRange = 10;

//카테고리
DataSet categories = category.getList(siteId);

//폼체크
f.addElement("s_req_sdate", null, null);
f.addElement("s_req_edate", null, null);
f.addElement("s_std_sdate", null, null);
f.addElement("s_std_edate", null, null);

f.addElement("s_year", null, null);
f.addElement("s_category", null, null);
f.addElement("s_type", null, null);
f.addElement("s_onofftype", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(course.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("a.id != " + m.ri("cid") + "");
lm.addWhere("a.id NOT IN (" + m.ri("idx") + ")");
if(!includePackage) lm.addWhere("a.onoff_type != 'P'");
if("C".equals(userKind)) lm.addWhere("a.id IN (" + manageCourses + ")");
lm.addSearch("a.year", f.get("s_year"));
lm.addSearch("a.course_type", f.get("s_type"));
lm.addSearch("a.onoff_type", f.get("s_onofftype"));
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

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 50));
	list.put("status_conv", m.getItem(list.s("status"), course.statusList));
	list.put("price_conv", m.nf(list.i("price")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("course_file_url", !"".equals(list.s("course_file")) ? siteDomain + m.getUploadUrl(list.s("course_file")) : "");
	list.put("cate_name", category.getTreeNames(list.i("category_id")));

	list.put("alltimes_block", "A".equals(list.s("course_type")));
	list.put("request_sdate_conv", m.time("yyyy.MM.dd", list.s("request_sdate")));
	list.put("request_edate_conv", m.time("yyyy.MM.dd", list.s("request_edate")));
	list.put("study_sdate_conv", m.time("yyyy.MM.dd", list.s("study_sdate")));
	list.put("study_edate_conv", m.time("yyyy.MM.dd", list.s("study_edate")));

	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffPackageTypes));
}


//출력
p.setLayout("pop");
p.setVar("p_title", "과정선택");
p.setBody("course.course_select");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("type_query", m.qs("id,mode,type"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(course.statusList));
p.setLoop("categories", categories);
p.setLoop("types", m.arr2loop(course.types));
p.setLoop("onoff_types", m.arr2loop(includePackage ? course.onoffPackageTypes : course.onoffTypes));
p.setLoop("years", mcal.getYears());
p.setVar("this_year", m.time("yyyy"));

p.setVar("form", form);
p.setVar("auto_block", "auto".equals(mode));
p.setVar("precede_block", "precede".equals(mode));
p.display();

%>