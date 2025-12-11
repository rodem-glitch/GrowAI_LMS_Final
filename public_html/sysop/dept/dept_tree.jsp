<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(43, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

//인원
Hashtable<String, String> deptMap = new Hashtable<String, String>();
DataSet ulist = user.query(
	" SELECT a.dept_id, COUNT(*) cnt "
	+ " FROM " + user.table + " a "
	+ " INNER JOIN " + userDept.table + " d on a.dept_id = d.id "
	+ " WHERE a.site_id = " + siteId + " AND a.status != -1 "
	+ " GROUP BY a.dept_id "
);
while(ulist.next()) {
	String key = ulist.s("dept_id");
	if(!deptMap.containsKey(key)) {
		deptMap.put(key, ulist.s("cnt"));
	}
}

//목록
DataSet list = userDept.getAllList(siteId);
//DataSet list = userDept.find("status != -1 AND site_id = " + siteId + "", "*", "parent_id ASC, sort ASC");
while(list.next()) {
	String key = list.s("id");
	list.put("cnt", deptMap.containsKey(key) ? deptMap.get(key) : "0");
	list.put("cnt_conv", m.nf(list.i("cnt")));

	list.put("use_block", list.i("status") == 1);
	list.put("status_conv", m.getItem(list.s("status"), userDept.statusList));
}
/*
DataSet list = userDept.query(
	" SELECT a.*, (SELECT COUNT(*) FROM " + user.table + " WHERE dept_id = a.id) cnt "
	+ " FROM " + userDept.table + " a "
	+ " WHERE a.status != -1 AND a.site_id = " + siteId
	+ " ORDER BY a.parent_id ASC, a.sort ASC "
);
DataSet list = userDept.query(
	" SELECT a.*, COUNT(u.id) cnt "
	+ " FROM " + userDept.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.id = u.dept_id AND u.status != -1 "
	+ " WHERE a.status != -1 AND a.site_id = " + siteId
	+ " GROUP BY a.id "
	+ " ORDER BY a.parent_id ASC, a.sort ASC "
);
while(list.next()) {
	list.put("use_block", list.i("status") == 1);
	list.put("cnt_conv", m.nf(list.i("cnt")));
}
*/

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "회원소속관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>고유값", "parent_id=>상위고유값", "depth=>깊이", "sort=>순서", "dept_nm=>소속명", "name_conv=>전체소속명", "dept_cd=>소속코드", "dept_desc=>소속설명", "cnt=>소속회원수", "status_conv=>상태" }, "회원소속관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setLayout("blank");
p.setBody("dept.dept_tree");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());

p.setLoop("list", list);
p.display();

%>