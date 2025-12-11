<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(18, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
GroupDao group = new GroupDao();

//폼체크
f.addElement("group_nm", null, "hname:'그룹명', required:'Y'");
f.addElement("description", null, "hname:'설명'");
f.addElement("disc_ratio", 0, "hname:'그룹할인률', option:'number', min:'0', max:'100', required:'Y'");
f.addElement("status", 1, "hname:'상태', required:'Y', option:'number'");

//등록
if(m.isPost() && f.validate()) {

	int newId = group.getSequence();
	group.item("id", newId);
	group.item("site_id", siteinfo.i("id"));
	group.item("group_nm", f.get("group_nm"));
	group.item("description", f.get("description"));
	group.item("disc_ratio", f.getInt("disc_ratio"));
	group.item("reg_date", m.time("yyyyMMddHHmmss"));
	group.item("status", f.getInt("status"));

	if(!group.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; 	}

	m.jsReplace("group_modify.jsp?id=" + newId, "parent");
	return;
}

//출력
p.setBody("user.group_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("status_list", m.arr2loop(group.statusList));
p.display();

%>