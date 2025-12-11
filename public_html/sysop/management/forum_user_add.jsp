<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGER

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//기본키
int fid = m.ri("fid");
if(fid == 0 || courseId == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();
CourseUserDao courseUser = new CourseUserDao();
ForumUserDao forumUser = new ForumUserDao();

//변수
String now = m.time("yyyyMMddHHmmss");

//처리
if("add".equals(m.rs("mode"))) {
	//기본키
	String idx = m.rs("idx");
	if("".equals(idx)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	//목록-수강생
	forumUser.item("forum_id", fid);
	forumUser.item("course_id", courseId);
	forumUser.item("site_id", siteId);
	forumUser.item("post_cnt", 0);
	forumUser.item("marking_score", 0);
	forumUser.item("score", 0);
	forumUser.item("feedback", "집합교육");
	forumUser.item("submit_yn", "Y");
	forumUser.item("confirm_yn", "N");
	forumUser.item("confirm_date", "");
	forumUser.item("course_user_id", 0);
	forumUser.item("mod_date", "");
	forumUser.item("reg_date", m.time("yyyyMMddHHmmss"));
	forumUser.item("status", 1);
	DataSet clist = courseUser.find("id IN (" + idx + ")", "id, user_id");
	while(clist.next()) {
		forumUser.item("course_user_id", clist.i("id"));
		forumUser.item("user_id", clist.i("user_id"));
		if(!forumUser.insert()) { }
	}

	m.jsAlert("추가되었습니다.");
	out.print("<script> try { opener.location.reload(); } catch (e) { } </script>");
	m.jsReplace("forum_user_add.jsp?" + m.qs("idx,mode"));
	return;

} else if("all".equals(m.rs("mode"))) {

	//목록-수강생
	forumUser.item("forum_id", fid);
	forumUser.item("course_id", courseId);
	forumUser.item("site_id", siteId);
	forumUser.item("post_cnt", 0);
	forumUser.item("score", 0);
	forumUser.item("feedback", "집합교육");
	forumUser.item("submit_yn", "Y");
	forumUser.item("confirm_yn", "N");
	forumUser.item("confirm_date", "");
	forumUser.item("course_user_id", 0);
	forumUser.item("mod_date", "");
	forumUser.item("reg_date", m.time("yyyyMMddHHmmss"));
	forumUser.item("status", 1);
	DataSet clist = courseUser.query(
		"SELECT a.id, a.user_id "
		+ " FROM " + courseUser.table + " a "
		+ " WHERE a.status IN (1,3) AND a.course_id = " + courseId + " "
		+ " AND NOT EXISTS ( "
			+ " SELECT 1 FROM " + forumUser.table + " "
			+ " WHERE forum_id = " + fid + " AND course_user_id = a.id "
		+ " ) "
	);
	while(clist.next()) {
		forumUser.item("course_user_id", clist.i("id"));
		forumUser.item("user_id", clist.i("user_id"));
		if(!forumUser.insert()) { }
	}

	m.jsAlert("추가되었습니다.");
	out.print("<script> try { opener.location.reload(); } catch (e) { } </script>");
	m.jsReplace("forum_user_add.jsp?" + m.qs("idx,mode"));
	return;

}

//폼체크
f.addElement("s_dept", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	courseUser.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " LEFT JOIN " + userDept.table + " d ON u.dept_id = d.id "
);
lm.setFields("a.id cuid, u.*, d.dept_nm");
lm.addWhere("a.status != -1");
lm.addWhere("a.course_id = " + courseId + "");
lm.addWhere("u.status = 1");
lm.addWhere("u.site_id = " + siteId + "");
lm.addWhere("NOT EXISTS ( "
	+ " SELECT 1 FROM " + forumUser.table + " "
	+ " WHERE forum_id = " + fid + " AND course_user_id = a.id "
+ " )");
if(deptManagerBlock) lm.addWhere("u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ")");
if(0 < f.getInt("s_dept")) lm.addWhere("u.dept_id IN (" + userDept.getSubIdx(siteId, f.getInt("s_dept")) + ")");
//lm.addSearch("u.dept_id", f.get("s_dept"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("u.user_nm,u.login_id", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "u.user_nm ASC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	if(0 < list.i("dept_id")) {	
		list.put("dept_nm_conv", userDept.getNames(list.i("dept_id")));
	} else {	
		list.put("dept_nm", "[미소속]");
		list.put("dept_nm_conv", "[미소속]");
	}	

	list.put("mobile_conv", "-");
	list.put("mobile_conv", !"".equals(list.s("mobile")) ? list.s("mobile") : "-" );
}

//남은수
int remainder = courseUser.getOneInt(
	"SELECT COUNT(*) "
	+ " FROM " + courseUser.table + " a "
	+ " WHERE a.status IN (1,3) AND a.course_id = " + courseId + " "
	+ " AND NOT EXISTS ( "
		+ " SELECT 1 FROM " + forumUser.table + " "
		+ " WHERE forum_id = " + fid + " AND course_user_id = a.id "
	+ " ) "
);

//출력
p.setLayout("pop");
p.setBody("management.forum_user_add");
p.setVar("p_title", "참여자 추가");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("uid,mode"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("dept_list", userDept.getList(siteId, userKind, userDeptId));
p.setVar("remainder_conv", remainder);
p.display();

%>