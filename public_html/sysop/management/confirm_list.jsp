<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(89, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CourseUserDao courseUser = new CourseUserDao();
UserDao user = new UserDao();

//처리
if("confirm".equals(m.rs("mode"))) {
	//기본키
	int cuid = m.ri("cuid");
	if(cuid == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	//정보
	DataSet cuinfo = courseUser.find("id = " + cuid + " AND status = 0");
	if(!cuinfo.next()) { m.jsAlert("해당 정보가 없습니다."); return; }

	courseUser.item("change_date", m.time("yyyyMMddHHmmss"));
	courseUser.item("status", 1);
	if(!courseUser.update("id = " + cuid + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsAlert("승인완료 하였습니다.");
	m.jsReplace("confirm_list.jsp?" + m.qs("mode,cuid"), "parent");
	return;
}

//폼체크
f.addElement("s_course", null, null);
f.addElement("s_onofftype", null, null);
f.addElement("s_type", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(
	courseUser.table + " a  "
	+ " INNER JOIN " + course.table + " c ON "
		+ " a.course_id = c.id AND c.status != -1 AND c.site_id = " + siteId + " "
	+ " LEFT JOIN " + course.table + " p ON a.package_id = p.id "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id "
);
lm.setFields(
	"a.id cuid, a.package_id, a.reg_date req_date, a.course_id, a.user_id "
	+ ", c.*, p.course_nm package_nm "
	+ ", u.login_id, u.user_nm "
);
lm.addWhere("a.status = 0");
lm.addSearch("a.course_id", f.get("s_course"));
lm.addSearch("c.onoff_type", f.get("s_onofftype"));
lm.addSearch("c.course_type", f.get("s_type"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("u.login_id, u.user_nm, c.course_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 40));

	list.put("type_conv", m.getItem(list.s("course_type"), course.types));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffTypes));

	list.put("package_block", 0 < list.i("package_id"));
	list.put("alltimes_block", "A".equals(list.s("course_type")));
	list.put("request_sdate_conv", m.time("yyyy.MM.dd", list.s("request_sdate")));
	list.put("request_edate_conv", m.time("yyyy.MM.dd", list.s("request_edate")));
	list.put("study_sdate_conv", m.time("yyyy.MM.dd", list.s("study_sdate")));
	list.put("study_edate_conv", m.time("yyyy.MM.dd", list.s("study_edate")));

	list.put("req_date_conv", m.time("yyyy.MM.dd", list.s("req_date")));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "과정승인관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>번호", "id=>과정아이디" , "type_conv=>구분" , "year=>년도" , "step=>기수" , "course_nm=>과정명" , "user_nm=>회원명" , "login_id=>회원아이디" , "reg_date_conv=>신청일" }, "과정승인관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("management.confirm_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,mode,cuid"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setLoop("courses", course.getCourseList(siteId));
p.setLoop("types", m.arr2loop(course.types));
p.setLoop("onoff_types", m.arr2loop(course.onoffTypes));
p.display();

%>