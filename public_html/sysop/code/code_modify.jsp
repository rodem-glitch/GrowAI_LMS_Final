<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(3, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//유효성검사
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CodeDao code = new CodeDao();

//정보
DataSet info = code.find("id = " + id);
if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

//상위메뉴정보
int pid = info.i("parent_id");
DataSet pinfo = code.find("id = " + pid);

//SORT
boolean isNext = pinfo.next();

if(!isNext) { pinfo.addRow(); }

//Sort
int maxSort = isNext ?
	code.findCount("site_id = " + siteinfo.i("id") + " AND parent_id = " + pinfo.s("id") + " AND depth = " + (pinfo.i("depth") + 1))
	: code.findCount("site_id = " + siteinfo.i("id") + " AND depth = 1");

DataSet sortList = new DataSet();
for(int i=0; i<maxSort; i++) {
	sortList.addRow();
	sortList.put("sort", i+1);
}

//폼체크
f.addElement("code", info.s("code"), "hname:'코드', required:'Y'");
f.addElement("code_nm", info.s("code_nm"), "hname:'코드명', required:'Y'");
f.addElement("description", info.s("description"), "hname:'코드설명'");
f.addElement("sort", info.s("sort"), "hname:'순서', required:'Y', option:'number'");

if(m.isPost() && f.validate()) {

	String newCode = f.get("code");

	//코드 중복 검사
	boolean isCode = !info.s("code").equals(newCode) ?
		(pinfo.i("id") != 0 ?
			code.findCount("site_id = " + siteinfo.i("id") + " AND depth=" + (pinfo.i("depth") + 1) + " AND parent_id=" + pinfo.s("id") + " AND code='" + newCode + "'") > 0
			: code.findCount("site_id = " + siteinfo.i("id") + " AND depth = 1 AND code='" + newCode + "'") > 0)
		: false;

	if(isCode) {
		m.jsError("이미 등록된 코드입니다.");
		return;
	}

	code.item("code", newCode);
	code.item("code_nm", f.get("code_nm"));
	code.item("description", f.get("description"));
//	code.item("sort", f.get("sort"));

	if(!code.update("id = '" + id + "'")) { m.jsAlert("수정하는 중 오류가 발행했습니다."); return; }

	code.sortDepth(id, f.getInt("sort"), info.getInt("sort"), siteId);

	out.print("<script>parent.left.location.href='code_tree.jsp?sid=" + info.s("id") + "';</script>");
	m.jsReplace("code_modify.jsp?" + m.qs());
	return;
}

code.pName = "parent_id";
code.nName = "code_nm";
code.rootNode = "0";
code.setData(code.find(""));
Vector pName = code.getParentNames(""+id);
String names = "";
for(int i=(pName.size() -1); i>0; i--) {
	names += pName.get(i).toString() + ( i == 1 ? "" : " > ");
}
info.put("parent_name", "".equals(names) ? "-" : names);

//출력
p.setLayout("blank");
p.setBody("code.code_insert");
p.setVar("p_title", "통합코드");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());
p.setVar("pinfo", pinfo);
p.setVar(info);
p.setVar("modify", true);
p.setLoop("sorts", sortList);
p.display();

%>