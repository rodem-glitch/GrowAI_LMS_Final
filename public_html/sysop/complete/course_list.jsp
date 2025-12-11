<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(76, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");
CourseUserDao courseUser = new CourseUserDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

MCal mcal = new MCal();
mcal.yearRange = 10;

//변수
String now = m.time("yyyyMMddHHmmss");

//처리
if(!deptManagerBlock && "close_y".equals(m.rs("mode"))) {
	int id = m.ri("id");
	if(id == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	DataSet culist = courseUser.find("status IN (1,3) AND close_yn = 'N' AND course_id = " + id + "");
	while(culist.next()) {
		if("".equals(culist.s("complete_yn"))) courseUser.completeUser(culist.i("id"));

		courseUser.item("close_yn", "Y");
		courseUser.item("close_date", now);
		courseUser.item("close_user_id", userId);
		courseUser.item("mod_date", now);
		if(!courseUser.update("id = " + culist.i("id") + "")) { }
	}

	course.item("close_yn", "Y");
	course.item("close_date", now);
	if(!course.update("id = " + id + "")) { }

	m.jsReplace("course_list.jsp?" + m.qs("id,mode"), "parent");
	return;

} else if(!deptManagerBlock && "close_n".equals(m.rs("mode"))) {
	int id = m.ri("id");
	if(id == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	course.item("close_yn", "N");
	course.item("close_date", "");
	if(!course.update("id = " + id + "")) { }

	m.jsReplace("course_list.jsp?" + m.qs("id,mode"), "parent");
	return;

}

//폼체크
f.addElement("s_year", null, null);
f.addElement("s_category", null, null);
f.addElement("s_type", null, null);
f.addElement("s_close", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//카테고리
DataSet categories = category.getList(siteId);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(course.table + " a");
lm.setFields(
	"a.* "
	+ ", (SELECT COUNT(*) FROM " + courseUser.table + " cuu "
		+ " INNER JOIN " + user.table + " uu ON cuu.user_id = uu.id " + (deptManagerBlock ? " AND uu.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
		+ " WHERE cuu.course_id = a.id AND cuu.status IN (1,3) "
	+ " ) user_cnt "
	+ ", (SELECT COUNT(*) FROM " + courseUser.table + " cuc "
		+ " INNER JOIN " + user.table + " uc ON cuc.user_id = uc.id " + (deptManagerBlock ? " AND uc.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
		+ " WHERE cuc.course_id = a.id AND cuc.complete_yn = 'Y' AND cuc.status IN (1,3) "
	+ " ) complete_cnt "
	//새로 추가 Start
	+ ", (SELECT COUNT(*) FROM " + courseUser.table + " cuc "
	+ " INNER JOIN " + user.table + " uc ON cuc.user_id = uc.id " + (deptManagerBlock ? " AND uc.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE cuc.course_id = a.id AND cuc.course_yn = 'Y' AND cuc.status IN (1,3) "
	+ " ) course_cnt "
	+ ", (SELECT COUNT(*) FROM " + courseUser.table + " cuc "
	+ " INNER JOIN " + user.table + " uc ON cuc.user_id = uc.id " + (deptManagerBlock ? " AND uc.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE cuc.course_id = a.id AND cuc.complete2_yn = 'Y' AND cuc.status IN (1,3) "
	+ " ) complete2_cnt "
	+ ", (SELECT COUNT(*) FROM " + courseUser.table + " cuc "
	+ " INNER JOIN " + user.table + " uc ON cuc.user_id = uc.id " + (deptManagerBlock ? " AND uc.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE cuc.course_id = a.id AND cuc.course2_yn = 'Y' AND cuc.status IN (1,3) "
	+ " ) course2_cnt "
	//새로 추가 End
);
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("a.onoff_type != 'P'");
if("C".equals(userKind)) lm.addWhere("a.id IN (" + manageCourses + ")");
lm.addSearch("a.year", f.get("s_year"));
lm.addSearch("a.course_type", f.get("s_type"));
lm.addSearch("a.close_yn", f.get("s_close"));
//if("C".equals(userKind)) lm.addWhere("a.manager_id = " + userId);
if(!"".equals(f.get("s_category"))) {
	lm.addWhere("a.category_id IN ( '" + m.join("','", category.getChildNodes(f.get("s_category"))) + "' )");
}
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.course_nm", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

System.out.println("=====> " + lm.getListQuery());
//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 70));
	list.put("status_conv", m.getItem(list.s("status"), course.statusList));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("cate_name", category.getTreeNames(list.i("category_id")));
	list.put("close_conv", list.b("close_yn") ? "종료" : "진행중");

	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffTypes));
	list.put("alltimes_yn", "A".equals(list.s("course_type")) ? "Y" : "N");
	list.put("alltimes_block", "A".equals(list.s("course_type")));
	list.put("study_sdate_conv", m.time("yyyy.MM.dd", list.s("study_sdate")));
	list.put("study_edate_conv", m.time("yyyy.MM.dd", list.s("study_edate")));

	int userCnt = list.i("user_cnt");
	double completeRate = userCnt > 0 ? list.i("complete_cnt") * 100 / list.i("user_cnt") : 0.00;
	double completeRate2 = userCnt > 0 ? list.i("complete2_cnt") * 100 / list.i("user_cnt") : 0.00;
	double course_cnt = userCnt > 0 ? list.i("course_cnt") * 100 / list.i("user_cnt") : 0.00;
	double course2_cnt = userCnt > 0 ? list.i("course2_cnt") * 100 / list.i("user_cnt") : 0.00;
	list.put("user_cnt_conv", m.nf(userCnt));
	list.put("complete_rate_conv", m.nf(completeRate, 1));
	//새로 추가 Start
	list.put("complete_rate_conv2", m.nf(completeRate2, 1));
	list.put("complete_course_conv", m.nf(course_cnt, 1));
	list.put("complete_course_conv2", m.nf(course2_cnt, 1));
	//새로 추가 End
	list.put("uncompl_cnt", userCnt - list.i("complete_cnt"));
}


//출력
p.setBody("complete.course_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("mode_query", m.qs("id,mode"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(course.statusList));
p.setLoop("categories", categories);
p.setLoop("years", mcal.getYears());
p.setLoop("types", m.arr2loop(course.types));

p.setVar("this_year", m.time("yyyy"));
p.setVar("today", m.time("yyyyMMdd"));
p.display();
%>