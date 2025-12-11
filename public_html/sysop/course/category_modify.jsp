<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(22, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
LmCategoryDao category = new LmCategoryDao("course");
CourseDao course = new CourseDao();

if(m.ri("category_id") > 0) {
	String[] idx = m.reqArr("idx");
	if(idx != null && idx.length > 0) {
		for(int i = 0; i < idx.length; i++) {
			course.item("sort", i);
			course.update("id = " + idx[i]);
		}

		category.item("sort_type", "st asc");
		if(!category.update("id = " + id + "")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

		m.redirect("category_modify.jsp?id=" + id);
		return;
	}
}

//정보
DataSet info = category.find("id = " + id + " AND status = 1 AND module = 'course' AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//변수
boolean changed = m.isPost() && !"".equals(f.get("parent_id")) && !info.s("parent_id").equals(f.get("parent_id"));
int pid = changed ? f.getInt("parent_id") : info.i("parent_id");

//정보-상위
DataSet pinfo = category.find("id = " + pid + " AND status = 1 AND module = 'course' AND site_id = " + siteId + "");
boolean isNext = pinfo.next();
if(!isNext) pinfo.addRow();

int maxSort = isNext ?
	category.findCount("site_id = " + siteId + " AND status = 1 AND module = 'course' AND parent_id = " +  pinfo.i("id") + " AND depth = " + (pinfo.i("depth") + 1))
	: category.findCount("site_id = " + siteId + " AND status = 1 AND module = 'course' AND depth = 1");


//순서
DataSet sortList = new DataSet();
for(int i = 0; i < maxSort; i++) {
	sortList.addRow();
	sortList.put("idx", i+1);
}

//폼체크
f.addElement("category_nm", info.s("category_nm"), "hname:'카테고리명', required:'Y'");
f.addElement("sort", info.i("sort"), "hname:'순서', required:'Y', option:'number'");
f.addElement("list_type", info.s("list_type"), "hname:'과정목록타입', required:'Y'");
f.addElement("sort_type", info.s("sort_type"), "hname:'과정정렬순서', required:'Y'");
f.addElement("list_num", info.i("list_num"), "hname:'목록갯수', required:'Y', option:'number', min:'5', max:'1000'");
f.addElement("display_yn", info.s("display_yn"), "hname:'메뉴노출여부'");

if(m.isPost() && f.validate()) {

	DataSet categories = category.getList(siteId);

	category.item("parent_id", 0 == pid ? 0 : pid);
	category.item("category_nm", f.get("category_nm"));
	category.item("list_type", f.get("list_type"));
	category.item("sort_type", f.get("sort_type"));
	category.item("list_num", f.get("list_num"));
	category.item("display_yn", f.get("display_yn", "N"));
	if(!changed) category.item("depth", pinfo.i("depth") + 1);
	category.item("sort", f.getInt("sort"));

	if(!category.update("id = " + id + "")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	if(changed) { // 부모가 변경 되었을 경우
		int cdepth = pinfo.i("depth") + 1 - info.i("depth");
		if(cdepth != 0) {
			category.execute("UPDATE " + category.table + " SET depth = depth + (" + cdepth + ") WHERE id IN (" + category.getSubIdx(siteId, id) + ")");
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

DataSet list = course.find("category_id IN (" + category.getSubIdx(siteId, id) + ") AND status != -1 AND close_yn = 'N' ORDER BY sort, id DESC");
while(list.next()) {
	list.put("regular_block", "R".equals(list.s("course_type")));
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 40));
	list.put("status_conv", m.getItem(list.s("status"), course.statusList));
	list.put("display_yn_conv", m.getItem(list.s("display_yn"), course.displayYn));
	list.put("type_conv", m.getItem(list.s("course_type"), course.types));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffPackageTypes));
	if("A".equals(list.s("course_type"))) {
		list.put("request_date", "상시");
	} else {
		list.put("request_date", m.time("yyyy.MM.dd", list.s("request_sdate")) + " - " + m.time("yyyy.MM.dd", list.s("request_edate")));
	}
}

//출력
p.setLayout("blank");
p.setBody("course.category_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);
p.setLoop("list", list);

p.setVar("pinfo", pinfo);
p.setLoop("sorts", sortList);
p.setVar("top", pid == 0);
p.display();

%>