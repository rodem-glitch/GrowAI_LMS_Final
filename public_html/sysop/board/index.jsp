<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(80, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao(isBlindUser);
PostLogDao postLog = new PostLogDao(siteId);

//폼체크
f.addElement("s_category_id", null, null);
f.addElement("s_proc_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//순서저장
if(m.isPost()) {
	String idx[] = m.reqArr("id");
	String sorts[] = m.reqArr("sort");

	if(idx == null || sorts == null) { m.jsError("순서를 정렬할 강사가 없습니다."); return; }

	for(int i = 0; i < idx.length; i++) {
		post.item("sort", sorts[i]);
		post.update("id = " + idx[i] + " AND site_id = " + siteId);
	}

	m.redirect("index.jsp?" + m.qs("id,sort"));
	return;
}

//목록
ListManager lm = new ListManager(jndi);
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 60000 : f.getInt("s_listnum", 20));
lm.setTable(
	post.table + " a "
	+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id "
	+ " LEFT JOIN " + file.table + " f ON f.module = 'post' AND f.module_id = a.id AND f.main_yn = 'Y' "
	+ " LEFT JOIN " + user.table + " u ON u.site_id = " + siteId + " AND u.id = a.user_id "
	+ " LEFT JOIN " + postLog.table + " pl ON a.id = pl.post_id AND pl.log_type = 'assign' AND pl.site_id = " + siteId + " "
	+ " LEFT JOIN " + user.table + " pu ON pl.user_id = pu.id AND pu.site_id = " + siteId + " "
);
lm.setFields("a.*, c.category_nm, f.filename, u.login_id, pu.id assign_id, pu.user_nm assign_nm, pu.login_id assign_login_id");
lm.addWhere("a.status > -1");
lm.addWhere("a.board_id = " + bid + "");
if("qna".equals(btype)) lm.addWhere("a.depth = 'A'");
lm.addSearch("a.category_id", f.get("s_category_id"));
lm.addSearch("a.proc_status", f.get("s_proc_status"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.subject, a.content, a.writer, u.login_id", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.sort ASC, a.thread ASC, a.depth ASC");

//포맷팅
int no = 1;
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("mod_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("mod_date")));

	list.put("comment_conv", list.i("comm_cnt") > 0? "(" + list.i("comm_cnt") + ")" : "" );
	list.put("hit_conv", m.nf(list.i("hit_cnt")));
	list.put("recomm_conv", m.nf(list.i("recomm_cnt")));

	list.put("subject", m.htt(list.s("subject")));
	list.put("subject_conv", m.cutString(list.s("subject"), 76));
	list.put("content_conv", m.nl2br(list.s("content")));
	list.put("category_conv", binfo.b("category_yn") && !"".equals(list.s("category_nm")) ? "[" + list.s("category_nm") + "]" : "");
	list.put("reply_block", list.s("depth").length() > 1);

	list.put("user_id", list.i("user_id") > 0 ? list.s("user_id") : "");
	list.put("login_id_conv", "".equals(list.s("login_id")) ? "-" : list.s("login_id"));

	list.put("new_block", m.diffDate("H", list.s("reg_date"), m.time("yyyyMMddHHmmss")) <= newHour);
	list.put("notice_block", list.b("notice_yn"));
	list.put("status_conv", m.getItem(list.s("status"), post.statusList));
	list.put("display_yn_conv", m.getItem(list.s("display_yn"), post.displayYn));

	//타입별 처리
	if("board".equals(btype)) {	//리스트형
		//답글
		int replyWidth = (list.s("depth").length() - 1) * 15;
		list.put("reply_width", replyWidth > 200 ? 200 : replyWidth);

	} else if("qna".equals(btype)) {	//QNA
		list.put("proc_status_conv", m.getItem(list.s("proc_status"), post.procStatusList));
	}
	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), "이러닝 운영", list);

	ExcelWriter ex = new ExcelWriter(response, binfo.s("board_nm") + "(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>게시물아이디", "category_conv=>카테고리", "thread=>thread", "depth=>depth", "writer=>작성자", "login_id=>로그인아이디", "subject=>제목", "youtube_cd=>YouTube영상코드", "content_conv=>내용", "notice_yn=>공지글여부", "secret_yn=>비밀글여부", "hit_cnt=>조회수", "comm_cnt=>댓글수", "recomm_cnt=>추천수", "file_cnt=>첨부파일수", "display_yn_conv=>노출여부", "sort=>FAQ정렬순서", "proc_status_conv=>QNA답변상태", "mod_date_conv=>수정일시", "reg_date_conv=>등록일시", "status_conv=>상태"}, binfo.s("board_nm") + "(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}//

//빈컬럼-갤러리
DataSet xlist = new DataSet();
if("gallery".equals(btype)) {
	int remain = columnCnt - (list.size() % columnCnt);
	if(remain != columnCnt) {
		for(int i = 0; i < remain; i++) {
			xlist.addRow();
		}
	}
}

//공지사항/베스트/상위
DataSet notices = new DataSet();
if(binfo.b("notice_yn")) {
	notices = post.query(
		"SELECT a.*, c.category_nm, f.filename, u.login_id "
		+ " FROM " + post.table + " a "
		+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id "
		+ " LEFT JOIN " + file.table + " f ON f.module = 'post' AND f.module_id = a.id AND f.main_yn = 'Y' "
		+ " LEFT JOIN " + user.table + " u ON u.site_id = " + siteId + " AND u.id = a.user_id "
		+ " WHERE a.status = 1 AND a.board_id = " + bid + " "
		+ " AND a.notice_yn = 'Y' "
		+ " ORDER BY a.thread ASC, a.depth ASC "
	);

	no = 1;
	while(notices.next()) {
		notices.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", notices.s("reg_date")));
		notices.put("mod_date_conv", m.time("yyyy.MM.dd HH:mm", notices.s("mod_date")));

		notices.put("comment_conv", notices.i("comm_cnt") > 0? "(" + notices.i("comm_cnt") + ")" : "" );
		notices.put("hit_conv", m.nf(notices.i("hit_cnt")));
		notices.put("recomm_conv", m.nf(notices.i("recomm_cnt")));

		notices.put("subject", m.htt(notices.s("subject")));
		notices.put("subject_conv", m.cutString(notices.s("subject"), 80));
		notices.put("category_conv", binfo.b("category_yn") && !"".equals(notices.s("category_nm")) ? "[" + notices.s("category_nm") + "]" : "");
		notices.put("reply_block", notices.s("depth").length() > 1);
		notices.put("new_block", m.diffDate("H", notices.s("reg_date"), m.time("yyyyMMddHHmmss")) <= newHour);

		notices.put("user_id", notices.i("user_id") > 0 ? notices.s("user_id") : "");
		notices.put("login_id_conv", "".equals(notices.s("login_id")) ? "-" : notices.s("login_id"));
		notices.put("display_yn_conv", m.getItem(notices.s("display_yn"), post.displayYn));

		//타입별 처리
		if("gallery".equals(btype)) {			//갤러리형
			notices.put("subject_conv", m.cutString(notices.s("subject"), 16));
			notices.put("newline", no % columnCnt == 0 && notices.size() != no ? "</tr></tbody></table>\n<table align=\"center\" cellpadding=\"0\" cellspacing=\"0\"><tbody><tr align=\"center\">" : "");
			notices.put("picture_url", m.getUploadUrl(notices.s("filename")));

		} else if("webzine".equals(btype)) {	//웹진형
			notices.put("subject_conv", m.cutString(notices.s("subject"), 90));
			notices.put("content_conv", m.cutString(m.stripTags(notices.s("content")), 300));
			notices.put("picture_url", m.getUploadUrl(notices.s("filename")));
		}
		no++;
	}
}


//출력
p.setLayout(ch);
p.setBody("board.list");
p.setVar("p_title", binfo.s("board_nm"));
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());
p.setLoop("xlist", xlist);

p.setVar("board", binfo);
p.setLoop("categories", categories);
p.setLoop("notices", notices);
p.setLoop("proc_status_list", m.arr2loop(post.procStatusList));
p.display();

%>