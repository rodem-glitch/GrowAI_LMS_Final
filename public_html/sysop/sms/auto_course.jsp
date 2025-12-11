<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(42, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int aid = m.ri("aid");
if(aid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
SendAutoDao sendAuto = new SendAutoDao();
CourseDao course = new CourseDao();
CourseAutoDao courseAuto = new CourseAutoDao(siteId);
LmCategoryDao category = new LmCategoryDao("course");
CourseUserDao courseUser = new CourseUserDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

//정보
DataSet info = sendAuto.find("id = " + aid + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }


//처리
if("add".equals(f.get("mode"))) {
	//기본키
	int crid = f.getInt("crid");
	if(crid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	//정보
	DataSet crinfo = course.find("id = " + crid + " AND site_id = " + siteId + " AND status != -1");
	if(!crinfo.next()) { m.jsError("해당 과정정보가 없습니다."); return; }

	if(!courseAuto.add(aid, crid)) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.jsAlert("추가 되었습니다.");
	m.jsReplace("auto_course.jsp?aid=" + aid);
	return;
} else if("madd".equals(f.get("mode"))) {
	//기본키
	String idx = f.get("idx");
	if("".equals(idx)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	//목록
	int success = 0;
	DataSet clist = course.find("id IN (" + idx + ") AND site_id = " + siteId + " AND status != -1", "id");
	while(clist.next()) {
		if(courseAuto.add(aid, clist.i("id"))) success++;
	}

	m.jsAlert(success + "개의 과정을 추가 되었습니다.");
	m.jsReplace("auto_course.jsp?aid=" + aid);
	return;
} else if("del".equals(f.get("mode"))) {
	//기본키
	int crid = f.getInt("crid");
	if(crid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	//정보
	DataSet crinfo = course.find("id = " + crid + " AND site_id = " + siteId + " AND status != -1");
	if(!crinfo.next()) { m.jsError("해당 과정정보가 없습니다."); return; }

	if(!courseAuto.del(aid, crid)) { }

	m.jsAlert("삭제 되었습니다.");
	m.jsReplace("auto_course.jsp?aid=" + aid);
	return;
}

//카테고리
DataSet categories = category.getList(siteId);

ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 60000 : f.getInt("s_listnum", 20));
lm.setTable(
	courseAuto.table + " a"
		+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.status != -1 "
);
lm.setFields(
	"c.* " + ", (SELECT COUNT(*) FROM " + courseUser.table + " cu "
		+ " INNER JOIN " + user.table + " u ON cu.user_id = u.id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
		+ " WHERE cu.course_id = c.id AND cu.status IN (1,3) "
		+ " ) user_cnt "
);
lm.addWhere("a.auto_id = " + aid + " ");
lm.addWhere("a.site_id = " + siteId + "");

DataSet list = lm.getDataSet();

while(list.next()) {
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 80));
	list.put("sale_yn_conv", m.getItem(list.s("sale_yn"), course.saleYn));
	list.put("display_yn_conv", m.getItem(list.s("display_yn"), course.displayYn));
	list.put("status_conv", m.getItem(list.s("status"), course.statusList));
	list.put("user_cnt_conv", m.nf(list.i("user_cnt")));
	list.put("package_block", "P".equals(list.s("onoff_type")));
	list.put("alltimes_block", "A".equals(list.s("course_type")));
	list.put("regular_block", "R".equals(list.s("course_type")));
	list.put("copy_block", !list.b("package_block"));
	list.put("cate_name", category.getTreeNames(list.i("category_id")));
	list.put("request_sdate_conv", m.time("yyyy.MM.dd", list.s("request_sdate")));
	list.put("request_edate_conv", m.time("yyyy.MM.dd", list.s("request_edate")));
	list.put("study_sdate_conv", m.time("yyyy.MM.dd", list.s("study_sdate")));
	list.put("study_edate_conv", m.time("yyyy.MM.dd", list.s("study_edate")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("course_file_url", !"".equals(list.s("course_file")) ? siteDomain + m.getUploadUrl(list.s("course_file")) : "");
	list.put("type_conv", m.getItem(list.s("course_type"), course.types));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffPackageTypes));
}

//m.p(list);

//출력
p.setLayout("sysop");
p.setBody("sms.auto_course");
p.setVar("p_title", "과정목록 - " + info.s("auto_nm"));
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("tab_course", "current");
p.display();

%>