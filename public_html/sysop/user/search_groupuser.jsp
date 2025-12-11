<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근 권한
if(!Menu.accessible(18, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String mode = m.rs("mode");
int gid = m.ri("gid");
if(gid == 0 || "".equals(mode)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();
GroupDao group = new GroupDao();
GroupUserDao groupUser = new GroupUserDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

//정보
DataSet ginfo = group.find("id = '" + gid + "' AND site_id = " + siteId + "");
if(!ginfo.next()) { m.jsAlert("해당 정보가 없습니다."); return; }
String deptStr = !"".equals(ginfo.s("depts")) ? ginfo.s("depts").substring(1, ginfo.s("depts").length() - 1) : "";

//추가
if(m.isPost() && f.validate()) {

	groupUser.item("group_id", gid);
	groupUser.item("site_id", siteId);
	groupUser.item("add_type", mode);

	String[] idx = f.getArr("idx");
	int total = 0;
	if(null != idx) {
		for(int i = 0; i < idx.length; i++) {
			groupUser.item("user_id", idx[i]);
			if(groupUser.insert()) total++;
		}
	}

	m.jsAlert("총 " + total + "명의 회원이 추가되었습니다.");
	m.js("parent.opener.location.href = parent.opener.location.href;parent.location.href = parent.location.href");
	return;

}

//폼체크
f.addElement("s_dept", null, null);
f.addElement("s_user_kind", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_course_id", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(100);
lm.setTable(
	user.table + " a "
	+ " LEFT JOIN " + userDept.table + " d ON a.dept_id = d.id "
);
lm.setFields("a.*, d.dept_nm");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");

if(f.getInt("s_course_id") > 0) {
	DataSet rs = courseUser.find("course_id = " + f.getInt("s_course_id") + " AND status = 1", "user_id");
	StringBuffer sb = new StringBuffer();
	while(rs.next()) sb.append("," + rs.i("user_id"));
	lm.addWhere("a.id IN (0" + sb.toString() + ")");
}

lm.addWhere("NOT EXISTS (SELECT 1 FROM " + groupUser.table + " WHERE group_id = " + gid + " AND user_id = a.id)");
if(!"".equals(deptStr) && "A".equals(mode)) lm.addWhere("a.dept_id NOT IN (" + m.join(",", deptStr.split("\\|")) + ") ");
if(0 < f.getInt("s_dept")) lm.addWhere("a.dept_id IN (" + userDept.getSubIdx(siteId, f.getInt("s_dept")) + ")");

lm.addSearch("a.user_kind", f.get("s_user_kind"));
//lm.addSearch("a.dept_id", f.get("s_dept"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.login_id, a.user_nm, a.email, a.etc1, a.etc2, a.etc3, a.etc4, a.etc5", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	String tmpGroups = group.getUserGroup(list);
	list.put("user_kind_conv", m.getItem(list.s("user_kind"), user.kinds));
	list.put("add_cnt", "".equals(tmpGroups) ? 0 : m.split(",", tmpGroups).length);

	if(0 < list.i("dept_id")) {	
		list.put("dept_nm_conv", userDept.getNames(list.i("dept_id")));
	} else {	
		list.put("dept_nm", "[미소속]");
		list.put("dept_nm_conv", "[미소속]");
	}

	user.maskInfo(list);
}

//기록-개인정보조회
if(list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

//출력
p.setLayout("pop");
p.setBody("user.search_groupuser");
p.setVar("p_title", "그룹회원 추가");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("SITE_CONFIG", SiteConfig.getArr("user_etc_"));
p.setLoop("dept_list", userDept.getList(siteId));
p.setLoop("status_list", m.arr2loop(user.statusList));
p.setLoop("user_kinds", m.arr2loop(user.kinds));
p.setLoop("courses", course.getCourseList(siteId, userId, userKind));
p.display();

%>