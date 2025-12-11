<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(80, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//폼체크
f.addElement("category_id", null, "hname:'카테고리', required:'Y'");
f.addElement("file", null, "hname:'파일', required:'Y', allow:'xls'");

//등록
if(m.isPost() && f.validate()) {

	String[] required = { "col0", "col2" };
	File f1 = f.saveFile("file");
	if(f1 == null) {
		m.p("파일 업로드에 실패했습니다.");
		return;
	}

	String path = m.getUploadPath(f.getFileName("file"));
	DataSet records = new ExcelReader(path).getDataSet(1);
	if(!"".equals(path)) m.delFileRoot(path);

	if("Y".equals(f.get("del_all"))) {
		post.delete("site_id = " + siteId + " AND board_id = " + bid + " AND category_id = " + f.get("category_id", "0"));
	}

	//등록
	int success = 0;
	while(records.next()) {
		boolean flag = true;
		for(int j = 0; j < required.length; j++) {
			if("".equals(records.s(required[j]))) {
				flag = false;
				m.p(records.s("col0") + "|" + records.s("col2") + " => 유효성 체크 오류입니다.");
			}
		}

		if(flag) {

			int newId = post.getSequence();

			post.item("id", newId);
			post.item("site_id", siteId);
			post.item("board_id", bid);
			post.item("category_id", f.get("category_id", "0"));
			post.item("thread", post.getLastThread());
			post.item("depth", "A");

			if(!"".equals(records.s("col1"))) {
				post.item("user_id", post.getOneInt("SELECT id FROM " + new UserDao().table + " WHERE login_id = '" + records.s("col0").trim() + "'"));
			}

			post.item("writer", m.replace(records.s("col0").trim(), new String[] { "\n", "\r" }, " "));
			post.item("subject", m.replace(records.s("col2").trim(), new String[] { "\n", "\r" }, " "));
			post.item("content", "html".equals(f.get("content_type")) ? records.s("col3") : m.htt(records.s("col3")));
			post.item("notice_yn", "".equals(records.s("col4")) ? "N" : records.s("col4"));
			post.item("secret_yn", "".equals(records.s("col5")) ? "N" : records.s("col5"));
			post.item("hit_cnt", records.i("col6"));
			post.item("reg_date", records.s("col7").length() == 14 ? records.s("col7") : m.time());
			post.item("status", 1);

			if(post.insert()) success++;
			else {
				m.p(records.s("col0") + "|" + records.s("col2") + " => 게시물 등록 오류입니다.");
			}
		}
	}

	m.jsAlert("총 " + records.size() + " 개 중 " + success + " 개가 등록되었습니다.");
	m.jsReplace("index.jsp?code=" + code, "parent");
	return;

}

//출력
p.setBody("board.post_excel_insert");
p.setVar("p_title", "게시글 일괄 등록");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());
p.setLoop("categories", categories);
p.setVar("upload_area", true);
p.display();

%>