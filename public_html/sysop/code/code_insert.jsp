<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(3, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//아이디
//String pid = !"".equals(f.get("pcode")) ? f.get("pcode") : m.request("pid");
int pid = 0 != f.getInt("pcode") ? f.getInt("pcode") : m.ri("pid");

//객체
CodeDao code = new CodeDao();

//하위등록시 상위 정보
DataSet pinfo = code.get(""+pid);

boolean isNext = pinfo.next();

if(!isNext) pinfo.addRow();

//Sort
int maxSort = isNext ?
	code.findCount("site_id = " + siteinfo.i("id") + " AND parent_id=" + pinfo.i("id") + " AND depth = " + (pinfo.i("depth") + 1))
	: code.findCount("depth = 1");

DataSet sortList = new DataSet();
for(int i=0; i<=maxSort; i++) {
	sortList.addRow();
	sortList.put("sort", i+1);
}

//폼 체크
f.addElement("code", null, "hname:'코드', required:'Y'");
f.addElement("code_nm", null, "hname:'코드명', required:'Y'");
f.addElement("description", null, "hname:'코드설명'");
f.addElement("sort", (maxSort + 1), "hname:'순서', required:'Y', option:'number'");

//등록
if(m.isPost() && f.validate()) {

	//코드 중복 검사
	boolean isCode = 0 == pinfo.i("id") ?
		code.findCount("site_id = " + siteinfo.i("id") + " AND depth=" + (pinfo.getInt("depth") + 1) + " AND parent_id=" + pinfo.i("id") + " AND code='" + f.get("code") + "'") > 0
		: code.findCount("site_id = " + siteinfo.i("id") + " AND depth = 1 AND code= '" + f.get("code") + "'") > 0;

	if(isCode) {
		m.jsError("이미 등록된 코드입니다.");
		return;
	}
	code.item("site_id", siteId);
	code.item("parent_id", pinfo.i("id") == 0 ? 0 : pinfo.i("id"));
	code.item("code", f.get("code"));
	code.item("code_nm", f.get("code_nm"));
	code.item("description", f.get("description"));
	code.item("depth", pinfo.getInt("depth") + 1);
	//code.item("sort", f.getInt("sort"));

	if(!code.insert()) {
		m.jsError("등록하는 중 오류가 발생했습니다.");
		return;
	}
	int newId = code.getInsertId();

	//순서 정렬
	code.sortDepth(newId, f.getInt("sort"), maxSort + 1, siteinfo.i("id"));

	out.print("<script>parent.left.location.href='code_tree.jsp?sid=" + pinfo.getString("id") + "';</script>");
	m.jsReplace("code_insert.jsp?pid=" + pid);
	return;
}

//상위코드명
String names = "";
if(0 != pid) {
	code.pName = "parent_id";
	code.nName = "code_nm";
	code.rootNode = "0";
	code.setData(code.find(""));

	Vector pName = code.getParentNames(""+pid);
	for(int i=(pName.size() -1); i >= 0; i--) {
		names += pName.get(i).toString() + ( i == 0 ? "" : " > ");
	}
}


//출력
p.setLayout("blank");
p.setBody("code.code_insert");
p.setVar("p_title", "통합코드");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());
p.setVar("pinfo", pinfo);
p.setLoop("sorts", sortList);
p.setVar("parent_name", "".equals(names) ? "-" : names);
p.display();

%>