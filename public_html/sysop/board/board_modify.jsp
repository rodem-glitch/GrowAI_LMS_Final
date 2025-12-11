<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!(Menu.accessible(6, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

//객체
BoardDao board = new BoardDao();
UserDao user = new UserDao();
GroupDao group = new GroupDao();

//정보
DataSet info = board.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsAlert("해당 정보가 없습니다."); return; }

boolean excepted = m.inArray(info.s("code"), board.exceptions);

//폼체크
f.addElement("site_id", info.s("site_id"), "hname:'사이트아이디'");
if(!excepted) f.addElement("code", info.s("code"), "hname:'코드', required:'Y', pattern:'^[a-zA-Z]{1}[a-zA-Z0-9]{1,19}$', errmsg:'영문으로 시작하는 2-20자로 영문, 숫자 조합으로 입력하세요.'");
f.addElement("board_type", info.s("board_type"), "hname:'게시판 타입', required:'Y'");
f.addElement("board_nm", info.s("board_nm"), "hname:'게시판명', required:'Y'");
f.addElement("layout", info.s("layout"), "hname:'레이아웃', required:'Y'");
f.addElement("breadscrumb", info.s("breadscrumb"), "hname:'분류명'");
f.addElement("admins", info.s("admin_idx"), "hname:'관리자'");
f.addElement("auth_list", info.s("auth_list"), "hname:'목록 권한'");
f.addElement("auth_read", info.s("auth_read"), "hname:'읽기 권한'");
f.addElement("auth_write", info.s("auth_write"), "hname:'쓰기 권한'");
f.addElement("auth_reply", info.s("auth_reply"), "hname:'답글 권한'");
f.addElement("auth_comm", info.s("auth_comm"), "hname:'덧글 권한'");
f.addElement("auth_download", info.s("auth_download"), "hname:'다운로드 권한'");

f.addElement("notice_yn", info.s("notice_yn"), "hname:'공지사항 사용유무'");
f.addElement("reply_yn", info.s("reply_yn"), "hname:'답글 사용유무'");
f.addElement("comment_yn", info.s("comment_yn"), "hname:'덧글 사용유무'");
f.addElement("delete_yn", info.s("delete_yn"), "hname:'덧글달린글삭제가능여부'");
f.addElement("list_num", info.i("list_num"), "hname:'게시물수', required:'Y', option:'number', min:'10', max:'100'");
f.addElement("category_yn", info.s("category_yn"), "hname:'카테고리 사용유무'");
f.addElement("upload_yn", info.s("upload_yn"), "hname:'업로드 사용유무', required:'Y'");
f.addElement("image_yn", info.s("image_yn"), "hname:'이미지파일 노출여부'");
//f.addElement("captcha_yn", info.s("captcha_yn"), "hname:'자동등록방지 사용유무'");
f.addElement("private_yn", info.s("private_yn"), "hname:'개인게시판 사용여부'");

f.addElement("allow_type", info.s("allow_type"), "hname:'업로드 파일타입'");
f.addElement("header_html", null, "hname:'상단 HTML'");
f.addElement("user_template", null, "hname:'기본 게시물 내용'");
//f.addElement("footer_html", info.s("footer_html"), "hname:'하단 HTML'");
f.addElement("status", info.i("status"), "hname:'상태', required:'Y'");

//수정
if(m.isPost() && f.validate()) {

	//중복검사-코드
	if(!f.get("code").equals(info.s("code")) && board.findCount("code = '" + f.get("code") + "' AND site_id = " + siteId + "") > 0) {
		m.jsError("사용 중인 코드입니다. 다시 입력해 주세요");
		return;
	}

	board.item("board_type", f.get("board_type"));
	if(!f.get("code").equals(info.s("code"))) board.item("code", f.get("code"));
	board.item("board_nm", f.get("board_nm"));
	board.item("layout", f.get("layout"));
	board.item("breadscrumb", f.get("breadscrumb"));

	board.item("admin_idx", "|" + m.join("|", f.getArr("admin_id")) + "|");
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
	board.item("status", f.get("status"));

	if(!board.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생하였습니다."); return; }

	//이동
	m.jsReplace("board_list.jsp?" + m.qs("id"), "parent");
	return;
}

//포멧팅
info.put("board_type_conv", m.getItem(info.s("board_type"), board.types));
info.put("header_html", m.htt(info.s("header_html")));

//출력
p.setBody("board.board_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);
p.setVar("delete_block", !m.inArray(info.s("code"), board.exceptions));

p.setLoop("types", m.arr2loop(board.types));
p.setLoop("layouts", board.getLayouts(siteinfo.s("doc_root") + "/html/layout"));
p.setLoop("status_list", m.arr2loop(board.statusList));
p.setLoop("admin_list", user.find("status = 1 AND id IN ('" + m.replace(info.s("admin_idx"), "|", "','") + "')"));

p.setVar("excepted", excepted);
p.setLoop("kinds", m.arr2loop(user.kinds));
p.setLoop("groups", group.getList(siteId));
p.display();

%>