<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//기본키
int cid = m.ri("cid");
if("".equals(cid)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
CoursePackageDao coursePackage = new CoursePackageDao();
LmCategoryDao category = new LmCategoryDao("course");
MCal mcal = new MCal(); mcal.yearRange = 10;

//정보
DataSet pinfo = course.find("id = " + cid + " AND onoff_type = 'P' AND status != -1 AND site_id = " + siteId + "");
if(!pinfo.next()) { m.jsErrClose("해당 정보가 없습니다."); return; }

//등록
if(m.isPost() && f.validate()) {

	String[] idx = f.getArr("lidx");
	int failed = 0;
	if(idx != null) {
		int maxSort = coursePackage.getLastSort(cid);

		coursePackage.item("package_id", cid);

		DataSet items = course.query(
			"SELECT a.* "
			+ " FROM " + course.table + " a "
			+ " WHERE a.onoff_type != 'P' AND a.course_type = '" + pinfo.s("course_type") + "' AND a.status = 1 AND a.site_id = " + siteId + " "
			+ " AND a.id IN (" + m.join(",", idx) + ") "
			+ " AND NOT EXISTS ( "
				+ " SELECT 1 FROM " + coursePackage.table + " WHERE package_id = " + cid + " AND course_id = a.id "
			+ " ) "
		);
		while(items.next()) {
			coursePackage.item("course_id", items.s("id"));
			coursePackage.item("site_id", siteId);
			coursePackage.item("sort", ++maxSort);
			if(!coursePackage.insert()) { failed++; }
		}
	}

	//갱신
	coursePackage.autoSort(cid);

	if(0 < failed) { m.jsAlert(failed + "개의 과정 등록에 실패했습니다."); }
	else { m.jsAlert("성공적으로 추가했습니다."); }
	m.js("opener.location.href = opener.location.href; window.close();");
	return;
}

//카테고리
DataSet categories = category.getList(siteId);

//폼체크
f.addElement("s_req_sdate", null, null);
f.addElement("s_req_edate", null, null);
f.addElement("s_std_sdate", null, null);
f.addElement("s_std_edate", null, null);

f.addElement("s_year", null, null);
f.addElement("s_category", null, null);
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
lm.addWhere("NOT EXISTS( SELECT 1 FROM " + coursePackage.table + " WHERE site_id = " + siteId + " AND package_id = " + cid + " AND course_id = a.id )");
lm.addWhere("a.onoff_type != 'P'");
lm.addWhere("a.course_type = '" + pinfo.s("course_type") + "'");
if("C".equals(userKind)) lm.addWhere("a.id IN (" + manageCourses + ")");
lm.addSearch("a.year", f.get("s_year"));
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

	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffTypes));
}


//출력
p.setLayout("pop");
p.setVar("p_title", "과정선택");
p.setBody("course.package_course_select");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(course.statusList));
p.setLoop("categories", categories);
p.setLoop("types", m.arr2loop(course.types));
p.setLoop("onoff_types", m.arr2loop(course.onoffTypes));
p.setLoop("years", mcal.getYears());
p.setVar("this_year", m.time("yyyy"));

p.display();

%>