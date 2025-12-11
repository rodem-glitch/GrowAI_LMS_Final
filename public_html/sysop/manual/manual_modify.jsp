<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(92, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ManualDao manual = new ManualDao();

//정보
DataSet info = manual.find("id = " + id + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//파일삭제
if("fdel".equals(m.rs("mode"))) {
	if(!"".equals(info.s("manual_file"))) {
		manual.item("manual_file", "");
		if(!manual.update("id = " + id + "")) { }
		m.delFileRoot(m.getUploadPath(info.s("manual_file")));
	}
	return;
}

//상위 정보
DataSet pinfo = manual.find("id = " + info.s("parent_id") + "");
int maxSort = pinfo.next() ? manual.findCount("parent_id = " + pinfo.s("id") + " AND depth = " + (pinfo.i("depth") + 1)) : manual.findCount("depth = 1");

//순서
DataSet sortList = new DataSet();
for(int i=1; i<=maxSort; i++) {
	sortList.addRow();
	sortList.put("sort", i);
}


//폼체크
f.addElement("manual_nm", info.s("manual_nm"), "hname:'매뉴얼명', required:'Y'");
f.addElement("manual_file", null, "hname:'매뉴얼파일'");
f.addElement("manual_video", info.s("manual_video"), "hname:'매뉴얼동영상'");
f.addElement("description", null, "hname:'내용'");
f.addElement("tag", info.s("tag"), "hname:'태그'");
f.addElement("sort", info.s("sort"), "hname:'순서', required:'Y', option:'number'");
f.addElement("status", info.s("status"), "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	manual.item("manual_nm", f.get("manual_nm"));

	if(null != f.getFileName("manual_file")) {
		File f1 = f.saveFile("manual_file");
		if(f1 != null) manual.item("manual_file", f.getFileName("manual_file"));
		if(!"".equals(info.s("manual_file"))) m.delFileRoot(m.getUploadPath(info.s("manual_file")));
	}

	manual.item("manual_video", f.get("manual_video"));
	manual.item("tag", f.get("tag"));
	manual.item("depth", pinfo.i("depth") + 1);
	manual.item("sort", f.getInt("sort"));
	manual.item("status", f.getInt("status"));

	if(!manual.update("id = " + id + "")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	manual.sortManual(info.i("id"), f.getInt("sort"), info.i("sort"));

	out.print("<script>parent.left.location.href='manual_tree.jsp?sid=" + info.s("parent_id") + "';</script>");
	m.jsReplace("manual_modify.jsp?" + m.qs());
	return;
}

//포맷팅
info.put("manual_file_conv", m.encode(info.s("manual_file")));
info.put("manual_file_url", m.getUploadUrl(info.s("manual_file")));
info.put("manual_file_ek", m.encrypt(info.s("manual_file") + m.time("yyyyMMdd")));

//출력
p.setLayout("blank");
p.setBody("manual.manual_insert");
p.setVar("p_title", "매뉴얼 관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setVar("pinfo", pinfo);
p.setLoop("sort_list", sortList);
p.display();

%>