<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGER

//접근권한
//if(!Menu.accessible(75, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//기본키
int courseId = m.ri("cid");
if(courseId == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
TutorDao tutor = new TutorDao();

//정보
DataSet cinfo = course.find(
	"id = " + courseId + " AND site_id = " + siteId + " AND status != -1"
	+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
);
if(!cinfo.next()) { m.jsAlert("해당 과정정보가 없습니다."); return; }

//등록
if(m.isPost() && !"".equals(f.get("uid"))) {

	//수강신청
	String[] idx = f.get("uid").split("\\,");
	for(int i=0; i<idx.length; i++) {
		courseUser.addUser(cinfo, m.parseInt(idx[i]), 1);
	}

	m.jsAlert("등록되었습니다.");
	out.print("<script> try { opener.location.reload(); } catch (e) { } </script>");
	m.jsReplace("user_add.jsp?" + m.qs("uid"));
	return;

}

//폼체크
f.addElement("s_dept", null, null);
f.addElement("s_kind", "", null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("add_search".equals(m.rs("mode")) ? 1000000 : f.getInt("s_listnum", 20));
lm.setTable(
	user.table + " a "
	+ " LEFT JOIN " + userDept.table + " d ON a.dept_id = d.id "
);
lm.setFields("a.*, d.dept_nm");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteId + "");
//lm.addWhere("NOT EXISTS (SELECT 1 FROM " + courseUser.table + " WHERE course_id = " + courseId + " AND user_id = a.id)");
if(deptManagerBlock) lm.addWhere("a.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ")");
if(0 < f.getInt("s_dept")) lm.addWhere("a.dept_id IN (" + userDept.getSubIdx(siteId, f.getInt("s_dept")) + ")");
//lm.addSearch("a.dept_id", f.get("s_dept"));
lm.addSearch("a.user_kind", f.get("s_kind"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("a.user_nm,a.login_id", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.user_nm ASC");

DataSet list = lm.getDataSet();
if("add_search".equals(m.rs("mode"))) {
	//전체등록
	int success = 0;
	int failed = 0;
	while(list.next()) {
		m.js("parent.updateProgress('" + list.i("__asc") + "');");
		if(courseUser.addUser(cinfo, list.i("id"), 1)) success++;
		else failed++;
	}
	m.jsAlert(m.nf(list.size()) + "건의 등록이 완료됐습니다.\\n(성공 : " + m.nf(success) + "건 / 실패 : " + m.nf(failed) + "건)");

	//이동
	out.print("<script> try { parent.opener.location.reload(); } catch (e) { } </script>");
	m.jsReplace("user_add.jsp?" + m.qs("mode"), "parent");
	return;

} else {
	//포맷팅
	while(list.next()) {
		if(0 < list.i("dept_id")) {	
			list.put("dept_nm_conv", userDept.getNames(list.i("dept_id")));
		} else {	
			list.put("dept_nm", "[미소속]");
			list.put("dept_nm_conv", "[미소속]");
		}	

		list.put("mobile_conv", "-");
		list.put("mobile_conv", !"".equals(list.s("mobile")) ? list.s("mobile") : "-" );
		user.maskInfo(list);
	}
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

//출력
p.setLayout("pop");
p.setBody("course.user_add");
p.setVar("p_title", "수강생등록");
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("total_num", lm.getTotalNum());
p.setVar("pagebar", lm.getPaging());

p.setLoop("dept_list", userDept.getList(siteId, userKind, userDeptId));
p.setLoop("kind_list", m.arr2loop(user.kinds));
p.display();

%>