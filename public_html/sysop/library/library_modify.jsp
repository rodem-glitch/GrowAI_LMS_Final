<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(77, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
LibraryDao library = new LibraryDao();
LmCategoryDao category = new LmCategoryDao();
UserDao user = new UserDao();

//정보
DataSet info = library.query(
	"SELECT a.*, u.user_nm manager_name "
	+ " FROM " + library.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
	+ " WHERE a.id = " + id + " AND a.status != -1 AND a.site_id = " + siteId + ""
	+ (courseManagerBlock ? " AND a.manager_id IN (-99, " + userId + ")" : "")
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//파일삭제
if("fdel".equals(m.rs("mode"))) {
	if(!"".equals(info.s("library_file"))) {
		library.item("library_file", "");
		if(!library.update("id = " + id)) { m.jsAlert("파일을 삭제하는 중 오류가 발생했습니다."); return; }
		m.delFile(m.getUploadPath(info.s("library_file")));
	}
	return;
}

//폼체크
f.addElement("category_id", info.s("category_id"), "hname:'카테고리명'");
f.addElement("library_nm", info.s("library_nm"), "hname:'자료명', required:'Y'");
f.addElement("content", null, "hname:'자료설명'");
f.addElement("library_file", null, "hname:'자료파일'");
f.addElement("library_link", info.s("library_link"), "hname:'자료링크'");
if(!courseManagerBlock) f.addElement("manager_id", info.s("manager_id"), "hname:'담당자'");
if(!courseManagerBlock) f.addElement("manager_name", info.s("manager_name"), "hname:'담당자'");
f.addElement("status", info.i("status"), "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	library.item("category_id", f.get("category_id"));
	library.item("library_nm", f.get("library_nm"));
	library.item("library_link", f.get("library_link"));
	library.item("content", f.get("content"));
	if(!courseManagerBlock) library.item("manager_id", f.getInt("manager_id"));
	library.item("status", f.get("status"));

	if(null != f.getFileName("library_file")) {
		File f1 = f.saveFile("library_file");
		if(f1 != null) {
			library.item("library_file", f.getFileName("library_file"));
			if(!"".equals(info.s("library_file"))) m.delFile(m.getUploadPath(info.s("library_file")));
		}
	}
	if(!library.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("library_list.jsp?" + m.qs("id"), "parent");
	return;

}

//포멧팅
info.put("content", m.htt(info.s("content")));
info.put("download_cnt_conv", m.nf(info.i("download_cnt")));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));
info.put("library_file_conv", m.encode(info.s("library_file")));
info.put("library_file_ek", m.encrypt(info.s("library_file") + m.time("yyyyMMdd")));


//출력
p.setBody("library.library_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setLoop("status_list", m.arr2loop(library.statusList));
p.setLoop("managers", user.getManagers(siteId));
p.setLoop("categories", category.getList(siteId));
p.display();

%>