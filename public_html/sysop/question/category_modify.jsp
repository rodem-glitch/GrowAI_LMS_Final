<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(71, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao();
QuestionCategoryDao category = new QuestionCategoryDao();

//정보
DataSet info = category.find("id = " + id + " AND status = 1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

//변수
boolean changed = m.isPost() && !"".equals(f.get("parent_id")) && !info.s("parent_id").equals(f.get("parent_id"));
int pid = changed ? f.getInt("parent_id") : info.i("parent_id");

//정보-상위
DataSet pinfo = category.find("id = " + pid + " AND status = 1 AND site_id = " + siteId +"");
boolean isNext = pinfo.next();
if(!isNext) pinfo.addRow();

int maxSort = isNext ?
	category.findCount("site_id = " + siteId + " AND status = 1 AND parent_id = " +  pinfo.i("id") + " AND depth = " + (pinfo.i("depth") + 1))
	: category.findCount("site_id = " + siteId + " AND status = 1 AND depth = 1");

//순서
DataSet sortList = new DataSet();
for(int i = 0; i < maxSort; i++) {
	sortList.addRow();
	sortList.put("idx", i+1);
}

//폼체크
f.addElement("category_nm", info.s("category_nm"), "hname:'카테고리명', required:'Y'");
if(!courseManagerBlock) f.addElement("sort", info.i("sort"), "hname:'순서', required:'Y', option:'number'");
if(!courseManagerBlock) f.addElement("manager_id", info.s("manager_id"), "hname:'담당자'");

if(m.isPost() && f.validate()) {

	DataSet categories = category.getList(siteId);

	category.item("parent_id", 0 == pid ? 0 : pid);
	category.item("category_nm", f.get("category_nm"));
	if(!changed) category.item("depth", pinfo.i("depth") + 1);
	if(!courseManagerBlock) category.item("sort", f.getInt("sort"));
	if(!courseManagerBlock) category.item("manager_id", f.getInt("manager_id"));

	if(!category.update("id = " + id + "")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	if(changed) { // 부모가 변경 되었을 경우
		int cdepth = pinfo.i("depth") + 1 - info.i("depth");
		if(cdepth != 0) {
			category.execute(
				"UPDATE " + category.table + " "
				+ " SET depth = depth + (" + cdepth + ") "
				+ " WHERE id IN ('" + m.join("','", category.getChildNodes(""+id)) + "')"
			);
		}

		// 이동된 위치를 다시 정렬한다.
		category.sortDepth(id, f.getInt("sort"), maxSort + 1, siteId);
		// 이동전 위치를 정렬한다.
		category.autoSort(info.i("depth"), info.i("parent_id"), siteId);
	} else {
		// 해당 위치만 정렬한다.
		category.sortDepth(id, f.getInt("sort"), info.i("sort"), siteId);
	}

	m.js("parent.left.location.href='category_tree.jsp?" + m.qs() + "&sid=" + id + "';");
	m.jsReplace("category_modify.jsp?" + m.qs());
	return;
}

//상위코드 명
DataSet categories = category.getList(siteId);
String pnames = category.getTreeNames(id);
info.put("parent_name", "".equals(pnames) ? "-" : pnames);


//출력
p.setLayout("blank");
p.setBody("question.category_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setVar("pinfo", pinfo);
p.setLoop("sorts", sortList);
p.setLoop("managers", user.getManagers(siteId));

p.display();

%>