<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(92, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//폼입력
int pid = m.ri("pid");

//객체
ManualDao manual = new ManualDao();

//순서
int maxSort = 0;
DataSet pinfo = new DataSet();
if(0 != pid) {
	pinfo = manual.find("id = " + pid + "");
	if(!pinfo.next()) {
		m.jsError("상위메뉴 정보가 없습니다.");
		return;
	}
	maxSort = manual.findCount("parent_id = " + pinfo.s("id") + " AND depth = " + (pinfo.i("depth") + 1));
} else {
	pinfo.addRow();
	pinfo.put("parent_id", "0");
	pinfo.put("depth", 0);
	maxSort = manual.findCount("depth = 1");
}

//순서
DataSet sortList = new DataSet();
for(int i=0; i<=maxSort; i++) {
	sortList.addRow();
	sortList.put("sort", i+1);
}


//폼체크
f.addElement("parent_id", null, "hname:'상위값'");
f.addElement("manual_nm", null, "hname:'매뉴얼명', required:'Y'");
f.addElement("manual_file", null, "hname:'매뉴얼파일'");
f.addElement("manual_video", null, "hname:'매뉴얼동영상'");
f.addElement("description", null, "hname:'내용'");
f.addElement("tag", null, "hname:'태그'");
f.addElement("sort", (maxSort + 1), "hname:'순서', required:'Y', option:'number'");
//f.addElement("status", null, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	int newId = manual.getSequence();
	manual.item("id", newId);
	manual.item("parent_id", "".equals(f.get("parent_id")) ? "0" : f.get("parent_id"));
	manual.item("manual_nm", f.get("manual_nm"));
	if(null != f.getFileName("manual_file")) {
		File f1 = f.saveFile("manual_file");
		if(f1 != null) manual.item("manual_file", f.getFileName("manual_file"));
	}

	manual.item("manual_video", f.get("manual_video"));
	manual.item("tag", f.get("tag"));
	manual.item("depth", pinfo.i("depth") + 1);
	manual.item("sort", f.getInt("sort"));
	manual.item("reg_date", m.time("yyyyMMddHHmmss"));
	manual.item("status", 0);

	if(!manual.insert()) { m.jsError("등록하는 중 오류가 발생했습니다."); return; }

	manual.sortManual(newId, f.getInt("sort"), maxSort + 1);

	out.print("<script>parent.left.location.href='manual_tree.jsp?sid=" + pid + "';</script>");
	m.jsReplace("manual_insert.jsp?pid=" + pid + "");
	return;
}

//출력
p.setLayout("blank");
p.setBody("manual.manual_insert");
p.setVar("p_title", "매뉴얼 관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("pinfo", pinfo);
p.setLoop("sort_list", sortList);
p.display();

%>