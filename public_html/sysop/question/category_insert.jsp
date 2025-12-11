<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(71, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao();
QuestionCategoryDao category = new QuestionCategoryDao();

int pid = 0 != f.getInt("parent_id") ? f.getInt("parent_id") : m.ri("pid");

//상위정보
DataSet pinfo = category.find("id = " + pid + " AND status = 1");
boolean isNext = pinfo.next();
if(!isNext) pinfo.addRow();

int maxSort = isNext ?
	category.findCount("site_id = " + siteId + " AND status = 1 AND parent_id = " + pinfo.i("id") + " AND depth = " + (pinfo.i("depth") + 1))
	: category.findCount("site_id = " + siteId + " AND status = 1 AND depth = 1");

DataSet sortList = new DataSet();
for(int i = 0; i <= maxSort; i++) {
	sortList.addRow();
	sortList.put("idx", i + 1);
}

//폼체크
f.addElement("category_nm", null, "hname:'카테고리명', required:'Y'");
if(!courseManagerBlock) f.addElement("sort", (maxSort + 1), "hname:'정렬', required:'Y', option:'number'");
if(!courseManagerBlock) f.addElement("manager_id", -99, "hname:'담당자'");

//등록
if(m.isPost()) {

	int newId = category.getSequence();
	int sort = f.getInt("sort");
	if(1 > sort) sort = maxSort;
	category.item("id", newId);
	category.item("site_id", siteId);
	category.item("parent_id", 0 == pid ? 0 : pid);
	category.item("category_nm", f.get("category_nm"));
	category.item("depth", pinfo.i("depth") + 1);
	category.item("sort", f.getInt("sort"));
	category.item("manager_id", !courseManagerBlock ? f.getInt("manager_id") : userId);
	category.item("status", 1);

	if(!category.insert()) { m.jsError("등록하는 중 오류가 발생했습니다."); return; }

	//정렬
	category.sortDepth(newId, sort, maxSort + 1, siteId);

	//이동
	m.js("parent.left.location.href='category_tree.jsp?" + m.qs("id, pid") + "&sid=" + pid + "';");
	m.jsReplace("category_insert.jsp?" + m.qs("id, pid") + "&pid=" + pid);
	return;
}

//상위코드 명
String pnames = "";
if(pid != 0) {
	DataSet categories = category.getList(siteId);
	pnames = category.getTreeNames(pid);
}

//출력
p.setLayout("blank");
p.setBody("question.category_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("parent_name", "".equals(pnames) ? "-" : pnames);
p.setVar("pinfo", pinfo);
p.setLoop("sorts", sortList);
p.setLoop("managers", user.getManagers(siteId));

p.display();

%>