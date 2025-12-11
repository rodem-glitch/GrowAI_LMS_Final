<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!(Menu.accessible(6, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
BoardDao board = new BoardDao();
UserDao user = new UserDao();
GroupDao group = new GroupDao();

//코드체크
if("CHECK".equals(m.rs("mode"))) {
	String value = m.rs("v");
	if("".equals(value)) { return; }

	//중복여부
	if(0 < board.findCount("code = '" + value + "' AND site_id = " + siteId + "")) {
		out.print("<span class='bad'>사용 중인 코드입니다. 다시 입력해 주세요.</span>");
	} else {
		out.print("<span class='good'>사용할 수 있는 코드입니다.</span>");
	}
	return;
}

//폼체크
f.addElement("code", null, "hname:'코드', required:'Y', pattern:'^[a-zA-Z]{1}[a-zA-Z0-9]{1,19}$', errmsg:'영문으로 시작하는 2-20자로 영문, 숫자 조합으로 입력하세요.'");
f.addElement("board_type", null, "hname:'게시판 타입', required:'Y'");
f.addElement("board_nm", null, "hname:'게시판명', required:'Y'");
f.addElement("layout", null, "hname:'레이아웃'");
f.addElement("breadscrumb", "학습지원센터", "hname:'분류명'");
f.addElement("admins", null, "hmame:'관리자'");
f.addElement("auth_list", null, "hname:'목록 권한'");
f.addElement("auth_read", null, "hname:'읽기 권한'");
f.addElement("auth_write", null, "hname:'쓰기 권한'");
f.addElement("auth_reply", null, "hname:'답글 권한'");
f.addElement("auth_comm", null, "hname:'덧글 권한'");
f.addElement("auth_download", null, "hname:'다운로드 권한'");
f.addElement("list_num", 10, "hname:'게시물수', required:'Y', option:'number', min:'10', max:'100'");
f.addElement("notice_yn", null, "hname:'공지사항 사용유무'");
f.addElement("reply_yn", null, "hname:'답글 사용유무'");
f.addElement("comment_yn", null, "hname:'덧글 사용유무'");
f.addElement("delete_yn", "Y", "hname:'덧글달린글삭제가능여부'");
f.addElement("category_yn", null, "hname:'카테고리 사용유무'");
f.addElement("upload_yn", null, "hname:'파일업로드 사용유무', required:'Y'");
f.addElement("image_yn", "Y", "hname:'이미지파일 노출여부'");
//f.addElement("captcha_yn", null, "hname:'자동등록방지 사용유무'");
f.addElement("private_yn", null, "hname:'개인게시판 사용여부'");
f.addElement("allow_type", "file", "hname:'업로드 파일타입'");
f.addElement("header_html", null, "hname:'상단 HTML', allowhtml:'Y'");
f.addElement("user_template", null, "hname:'기본 게시물 내용'");
//f.addElement("footer_html", null, "hname:'하단 HTML'");
f.addElement("status", null, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	//중복검사-코드
	if(board.findCount("code = '" + f.get("code") + "' AND site_id = " + siteId + "") > 0) { m.jsAlert("사용 중인 코드입니다. 다시 입력해 주세요.");	return; }

	board.item("site_id", siteId);
	board.item("board_type", f.get("board_type"));
	board.item("code", f.get("code"));
	board.item("board_nm", f.get("board_nm"));

	board.item("layout", f.get("layout", "board"));
	board.item("breadscrumb", f.get("breadscrumb"));
	board.item("admin_idx", "||");
	board.item("auth_list", "|" + m.join("|", f.getArr("auth_list")) + "|");
	board.item("auth_read", "|" + m.join("|", f.getArr("auth_read")) + "|");
	board.item("auth_write", "|" + m.join("|", f.getArr("auth_write")) + "|");
	board.item("auth_reply", "|" + m.join("|", f.getArr("auth_reply")) + "|");
	board.item("auth_comm", "|" + m.join("|", f.getArr("auth_comm")) + "|");
	board.item("auth_download", "|" + m.join("|", f.getArr("auth_download")) + "|");

	board.item("notice_yn", f.get("notice_yn", "N"));
	board.item("reply_yn", f.get("reply_yn", "N"));
	board.item("comment_yn", f.get("comment_yn", "N"));
	board.item("delete_yn", f.get("delete_yn", "N"));
	board.item("list_num", f.getInt("list_num", 10));
	board.item("category_yn", f.get("category_yn", "N"));
	board.item("image_yn", f.get("image_yn", "N"));
	board.item("captcha_yn", f.get("captcha_yn", "N"));
	board.item("private_yn", f.get("private_yn", "N"));

	board.item("upload_yn", f.get("upload_yn", "N"));
	if("Y".equals(f.get("upload_yn"))) {
		String[] allowTypes = f.getArr("allow_type");
		String denyExt = "|jpg|jpeg|gif|png|swf|mp4|flv|mov|qt|mpeg|wmv|wma|asf|mp3|avi|wmp|rmp|ra";
		for(int i = 0; i < allowTypes.length; i++) {
			if(!"file".equals(allowTypes[i])) denyExt = m.replace(denyExt, m.getItem(allowTypes[i], board.extTypes), "");
		}
		board.item("allow_type", m.join(",", f.getArr("allow_type")));
		board.item("deny_ext", !"".equals(denyExt)? denyExt.substring(1) : "");
	} else {
		board.item("allow_type", "");
		board.item("deny_ext", "");
	}

	board.item("header_html", f.get("header_html"));
	board.item("footer_html", f.get("footer_html"));
	board.item("user_template", f.get("user_template"));
	board.item("reg_date", m.time("yyyyMMddHHmmss"));
	board.item("status", f.get("status"));

	if(!board.insert()) { m.jsAlert("등록하는 중 오류가 발생하였습니다."); return;	}

	//이동
	m.jsReplace("board_list.jsp?" + m.qs(), "parent");
	return;
}


//출력
p.setBody("board.board_insert");
p.setVar("p_title", "게시판관리");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setLoop("types", m.arr2loop(board.types));
p.setLoop("layouts", board.getLayouts(siteinfo.s("doc_root") + "/html/layout"));
p.setLoop("status_list", m.arr2loop(board.statusList));

p.setLoop("kinds", m.arr2loop(user.kinds));
p.setLoop("groups", group.getList(siteId));
p.display();

%>