<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(927, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
LmCategoryDao category = new LmCategoryDao("webtv_playlist");
LmCategoryTargetDao categoryTarget = new LmCategoryTargetDao();
GroupDao group = new GroupDao();

//정보
DataSet info = category.find("id = " + id + " AND status = 1 AND module = 'webtv_playlist' AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

//변수
boolean changed = m.isPost() && !"".equals(f.get("parent_id")) && !info.s("parent_id").equals(f.get("parent_id"));
int pid = changed ? f.getInt("parent_id") : info.i("parent_id");

//정보-상위
DataSet pinfo = category.find("id = " + pid + " AND status = 1 AND module = 'webtv_playlist' AND site_id = " + siteId +"");
boolean isNext = pinfo.next();
if(!isNext) pinfo.addRow();

int maxSort = isNext ?
	category.findCount("site_id = " + siteId + " AND status = 1 AND module = 'webtv_playlist' AND parent_id = " +  pinfo.i("id") + " AND depth = " + (pinfo.i("depth") + 1))
	: category.findCount("site_id = " + siteId + " AND status = 1 AND module = 'webtv_playlist' AND depth = 1");

//순서
DataSet sortList = new DataSet();
for(int i = 0; i < maxSort; i++) {
	sortList.addRow();
	sortList.put("idx", i+1);
}

//폼체크
f.addElement("category_nm", info.s("category_nm"), "hname:'카테고리명', required:'Y'");
//f.addElement("list_type", info.s("list_type"), "hname:'목록타입', required:'Y'");
//f.addElement("sort_type", info.s("sort_type"), "hname:'정렬순서', required:'Y'");
f.addElement("list_num", info.i("list_num"), "hname:'목록갯수', required:'Y', option:'number'");
f.addElement("display_yn", info.s("display_yn"), "hname:'노출여부'");
f.addElement("target_yn", info.s("target_yn"), "hname:'시청대상그룹 사용여부', required:'Y'");
f.addElement("login_yn", info.s("login_yn"), "hname:'회원전용여부', required:'Y'");
f.addElement("sort", info.i("sort"), "hname:'순서', required:'Y', option:'number'");

if(m.isPost() && f.validate()) {

	DataSet categories = category.getList(siteId);

	category.item("parent_id", 0 == pid ? 0 : pid);
	category.item("category_nm", f.get("category_nm"));
	//category.item("list_type", f.get("list_type", "gallery"));
	//category.item("sort_type", f.get("sort_type", "id DESC"));
	category.item("list_num", f.get("list_num", "20"));
	category.item("display_yn", f.get("display_yn", "N"));
	category.item("target_yn", f.get("target_yn"));
	category.item("login_yn", f.get("login_yn"));
	if(!changed) category.item("depth", pinfo.i("depth") + 1);
	category.item("sort", f.getInt("sort"));

	if(!category.update("id = " + id + "")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	//그룹
	if(-1 != categoryTarget.execute("DELETE FROM " + categoryTarget.table + " WHERE category_id = " + id + "")) {
		if(null != f.getArr("group_id")) {
			categoryTarget.item("category_id", id);
			for(int i = 0; i < f.getArr("group_id").length; i++) {
				categoryTarget.item("group_id", f.getArr("group_id")[i]);
				categoryTarget.item("site_id", siteId);
				if(!categoryTarget.insert()) { }
			}
		}
	}

	if(changed) { // 부모가 변경 되었을 경우
		int cdepth = pinfo.i("depth") + 1 - info.i("depth");
		if(cdepth != 0) {
			category.execute(
				"UPDATE " + category.table + " "
				+ " SET depth = depth + (" + cdepth + ") "
				//+ " WHERE id IN ('" + m.join("','", category.getChildNodes(""+id)) + "')"
				+ " WHERE id IN (" + category.getSubIdx(siteId, id) + ")"
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

	m.js("parent.left.location.href='playlist_tree.jsp?" + m.qs() + "&sid=" + id + "';");
	m.jsReplace("playlist_modify.jsp?" + m.qs());
	return;
}

//상위코드 명
DataSet categories = category.getList(siteId);
String pnames = category.getTreeNames(id);
info.put("parent_name", "".equals(pnames) ? "-" : pnames);

//목록-대상자
DataSet targets = categoryTarget.query(
	"SELECT a.*, g.group_nm "
	+ " FROM " + categoryTarget.table + " a "
	+ " INNER JOIN " + group.table + " g ON a.group_id = g.id AND g.site_id = " + siteId + " "
	+ " WHERE a.category_id = " + id + ""
);

//출력
p.setLayout("blank");
p.setBody("webtv.playlist_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setLoop("targets", targets);

p.setVar("cid", id);
p.setVar("tab_modify", "current");
p.setVar("pinfo", pinfo);
p.setLoop("sorts", sortList);
p.display();

%>