<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(43, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDeptDao userDept = new UserDeptDao();

int pid = 0 != f.getInt("parent_id") ? f.getInt("parent_id") : m.ri("pid");

//상위정보
DataSet pinfo = userDept.find("id = " + pid + " AND status != -1");
boolean isNext = pinfo.next();
if(!isNext) pinfo.addRow();

int maxSort = isNext ?
	userDept.findCount("site_id = " + siteId + " AND status != -1 AND parent_id = " + pinfo.i("id") + " AND depth = " + (pinfo.i("depth") + 1))
	: userDept.findCount("site_id = " + siteId + " AND status != -1 AND depth = 1");

DataSet sortList = new DataSet();
for(int i = 0; i <= maxSort; i++) {
	sortList.addRow();
	sortList.put("sort", i + 1);
}

//폼체크
f.addElement("dept_nm", null, "hname:'분류명', required:'Y'");
f.addElement("dept_desc", null, "hname:'분류설명'");
f.addElement("sort", maxSort+1, "hname:'순서', required:'Y', option:'number'");
f.addElement("dept_cd", null, "hname:'소속코드'");
f.addElement("auth2_yn", "Y", "hname:'2차인증설정'");
f.addElement("display_yn", "Y", "hname:'노출여부'");
f.addElement("status", 1, "hname:'상태', required:'Y', option:'number'");

//등록
if(m.isPost()) {

	int newId = userDept.getSequence();
	userDept.item("id", newId);
	userDept.item("site_id", siteId);
	userDept.item("parent_id", 0 == pid ? 0 : pid);
	userDept.item("dept_nm", f.get("dept_nm"));
	userDept.item("dept_desc", f.get("dept_desc"));
	userDept.item("depth", pinfo.i("depth") + 1);
	userDept.item("sort", f.getInt("sort"));
	userDept.item("dept_cd", f.get("dept_cd"));
	userDept.item("auth2_yn", f.get("auth2_yn"));
	userDept.item("display_yn", f.get("display_yn", "N"));
	userDept.item("status", f.getInt("status"));
	if(!userDept.insert()) { m.jsError("등록하는 중 오류가 발생했습니다."); return; }

	//정렬
	userDept.sort(newId, f.getInt("sort"), maxSort + 1);

	//이동
	m.js("parent.left.location.href='dept_tree.jsp?" + m.qs("id, pid") + "&sid=" + pid + "';");
	m.jsReplace("dept_insert.jsp?" + m.qs("id, pid") + "&pid=" + pid);
	return;
}

//상위코드 명
String pnames = "";
if(pid != 0) {
	DataSet departmenta = userDept.getList(siteId);
	pnames = userDept.getTreeNames(pid);
}

//출력
p.setLayout("blank");
p.setBody("dept.dept_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("parent_name", "".equals(pnames) ? "-" : pnames);
p.setVar("pinfo", pinfo);

p.setLoop("sort_list", sortList);
p.setLoop("auth2_yn", m.arr2loop(userDept.auth2Yn));
p.setLoop("display_yn", m.arr2loop(userDept.displayYn));
p.setLoop("status_list", m.arr2loop(userDept.statusList));
p.display();

%>