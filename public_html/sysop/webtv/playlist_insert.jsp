<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(927, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
LmCategoryDao category = new LmCategoryDao("webtv_playlist");
LmCategoryTargetDao categoryTarget = new LmCategoryTargetDao();

int pid = 0 != f.getInt("parent_id") ? f.getInt("parent_id") : m.ri("pid");

//상위정보
DataSet pinfo = category.find("id = " + pid + " AND status = 1");
boolean isNext = pinfo.next();
if(!isNext) pinfo.addRow();

int maxSort = isNext ?
	category.findCount("site_id = " + siteId + " AND status = 1 AND module = 'webtv_playlist' AND parent_id = " + pinfo.i("id") + " AND depth = " + (pinfo.i("depth") + 1))
	: category.findCount("site_id = " + siteId + " AND status = 1 AND module = 'webtv_playlist' AND depth = 1");

DataSet sortList = new DataSet();
for(int i = 0; i <= maxSort; i++) {
	sortList.addRow();
	sortList.put("idx", i + 1);
}

//폼체크
f.addElement("category_nm", null, "hname:'카테고리명', required:'Y'");
//f.addElement("list_type", "gallery", "hname:'과정목록타입', required:'Y'");
//f.addElement("sort_type", null, "hname:'과정정렬순서', required:'Y'");
f.addElement("list_num", 20, "hname:'목록갯수', required:'Y', option:'number'");
f.addElement("display_yn", "Y", "hname:'메뉴노출여부'");
f.addElement("target_yn", "N", "hname:'시청대상그룹 사용여부', required:'Y'");
f.addElement("login_yn", "N", "hname:'회원전용여부', required:'Y'");
f.addElement("sort", (maxSort + 1), "hname:'정렬', required:'Y', option:'number'");

//등록
if(m.isPost()) {

	int newId = category.getSequence();
	category.item("id", newId);
	category.item("site_id", siteId);
	category.item("module", "webtv_playlist");
	category.item("parent_id", 0 == pid ? 0 : pid);
	category.item("category_nm", f.get("category_nm"));
	category.item("list_type", "gallery");
	category.item("sort_type", "sort ASC");
	category.item("list_num", f.get("list_num", "20"));
	category.item("display_yn", f.get("display_yn", "N"));
	category.item("target_yn", f.get("target_yn"));
	category.item("login_yn", f.get("login_yn"));
	category.item("depth", pinfo.i("depth") + 1);
	category.item("sort", f.getInt("sort"));
	category.item("status", 1);

	if(!category.insert()) { m.jsError("등록하는 중 오류가 발생했습니다."); return; }

	//그룹
	if(-1 != categoryTarget.execute("DELETE FROM " + categoryTarget.table + " WHERE category_id = " + newId + "")) {
		if(null != f.getArr("group_id")) {
			categoryTarget.item("category_id", newId);
			for(int i = 0; i < f.getArr("group_id").length; i++) {
				categoryTarget.item("group_id", f.getArr("group_id")[i]);
				categoryTarget.item("site_id", siteId);
				if(!categoryTarget.insert()) { }
			}
		}
	}

	//정렬
	category.sortDepth(newId, f.getInt("sort"), maxSort + 1, siteId);

	//이동
	m.js("parent.left.location.href='playlist_tree.jsp?" + m.qs("id, pid") + "&sid=" + pid + "';");
	m.jsReplace("playlist_insert.jsp?" + m.qs("id, pid") + "&pid=" + pid);
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
p.setBody("webtv.playlist_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("parent_name", "".equals(pnames) ? "-" : pnames);
p.setVar("pinfo", pinfo);
p.setLoop("sorts", sortList);

p.display();

%>