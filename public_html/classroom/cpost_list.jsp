<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String code = m.rs("code");
if("".equals(code)) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
ClBoardDao board = new ClBoardDao();
ClPostDao post = new ClPostDao();
ClFileDao file = new ClFileDao();

//기본게시판
if(m.inArray(code, board.baseCodes)) {
	if(0 == board.findCount("course_id = " + courseId + " AND code = '" + code + "'")) {
		board.item("site_id", siteId);
		board.item("course_id", courseId);
		board.item("code", code);
		board.item("board_nm", m.getValue(code, board.baseBoardNamesMsg));
		board.item("base_yn", "Y");
		board.item("board_type", m.getItem(code, board.baseTypes));
		board.item("content", "");
		board.item("sort", 999);
		board.item("link", "");
		board.item("write_yn", m.getItem(code, board.baseWriteYns));
		board.item("reg_date", m.time("yyyyMMddHHmmss"));
		board.item("status", 1);
		if(!board.insert()) { m.jsError(_message.get("alert.board.error_insert")); return; }

		//정렬
		board.autoSort(courseId);
	}
}

//정보-게시판
DataSet binfo = board.find("course_id = " + courseId + " AND code = '" + code + "' AND status = 1");
if(!binfo.next()) { m.jsError(_message.get("alert.board.nodata")); return; }
String btype = binfo.s("board_type");
binfo.put("type_" + btype, true);

//폼체크
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager(jndi);
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	post.table + " a "
	+ " INNER JOIN " + board.table + " b ON a.board_id = b.id AND b.code = '" + code + "' "
	+ " LEFT JOIN " + file.table + " f ON f.module = 'post' AND f.module_id = a.id AND f.main_yn = 'Y' "
);
lm.setFields("a.*, f.filename");
lm.addWhere("a.display_yn = 'Y'");
lm.addWhere("a.status = 1");
lm.addWhere("a.course_id = " + courseId + "");
if("qna".equals(btype)) lm.addWhere("a.depth = 'A'");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.subject,a.content,a.writer", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(f.get("ord")) ? f.get("ord") : "a.thread ASC, a.depth ASC");

//목록
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", m.time(_message.get("format.date.dot"), list.s("reg_date")));
	list.put("mod_date_conv", m.time(_message.get("format.date.dot"), list.s("mod_date")));

	list.put("comment_conv", binfo.b("comment_yn") && list.i("comm_cnt") > 0 ? "(" + list.i("comm_cnt") + ")" : "" );
	list.put("file_block", list.i("file_cnt") > 0);
	list.put("hit_cnt_conv", m.nf(list.i("hit_cnt")));
	list.put("new_block", m.diffDate("H", list.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);

	list.put("subject_conv", m.cutString(list.s("subject"), 60));
	list.put("reply_block", list.s("depth").length() > 1);
	list.put("secret_block", list.b("secret_yn") && userId != list.i("user_id"));
	list.put("writer_conv", "Y".equals(SiteConfig.s("masking_yn")) ? m.masking(list.s("writer")) : list.s("writer"));

	//타입별 처리
	if("list".equals(btype)) {	//리스트형
		//답글
		int replyWidth = (list.s("depth").length() - 1) * 15;
		list.put("reply_width", replyWidth > 200 ? 200 : replyWidth);
	} else if("qna".equals(btype)) {	//QNA
		list.put("proc_status_conv", m.getValue(list.s("proc_status"), post.procStatusListMsg));
		list.put("mod_date_conv", list.i("proc_status") == 2 ? m.time(_message.get("format.date.dot"), list.s("mod_date")) : "-");
	}
}

//탬플릿
String body = "clist";
if("qna".equals(btype)) body = "cqna";

//출력
p.setLayout(ch);
p.setBody("classroom." + body);
p.setVar("p_title", binfo.s("board_nm"));
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setVar("board", binfo);
p.setVar("active_" + code, "select");
p.display();

%>