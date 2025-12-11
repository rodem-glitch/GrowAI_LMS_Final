<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(80, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao(isBlindUser);

//정보
DataSet info = post.query(
	" SELECT a.*, u.login_id FROM " + post.table + " a "
	+ " LEFT JOIN " + user.table + " u ON u.site_id = " + siteId + " AND u.id = a.user_id "
	+ " WHERE a.id = " + id + " AND a.site_id = " + siteId + " AND a.status != -1 "
);
if(!info.next()) { m.jsError("해당 게시물이 없습니다."); return; }
info.put("subject", m.htt(info.s("subject")));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("mod_date_block", !"".equals(info.s("mod_date")));
info.put("mod_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("mod_date")));
info.put("user_id", info.i("user_id") > 0 ? info.s("user_id") : "");
info.put("login_id_conv", "".equals(info.s("login_id")) ? "-" : info.s("login_id"));
info.put("comment_conv", info.i("comm_cnt") > 0 ? "(" + info.i("comm_cnt") + ")" : "" );
info.put("hit_conv", m.nf(info.i("hit_cnt")));
info.put("recomm_conv", m.nf(info.i("recomm_cnt")));
info.put("new_block", m.diffDate("H", info.s("reg_date"), m.time("yyyyMMddHHmmss")) <= newHour);
info.put("notice_block", info.b("notice_yn"));
String categoryName = binfo.b("category_yn") ? category.getName(categories, info.s("category_id")) : "" ;
info.put("category_conv", !"".equals(categoryName) ? "[" + categoryName + "]" : "");

info.put("content", info.s("content").replaceAll("&", "&amp;").replaceAll("\"", "&quot;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll("'", "&#39;").replaceAll("/", "&#x2F;").replaceAll("\\(", "&#40;").replaceAll("\\)", "&#41;"));

Vector<String> keywordVec = new Vector<String>();
String[] keywords = !"".equals(info.s("keyword"))? info.s("keyword").split("\\,") : new String[] {};
for(int i = 0; i < keywords.length; i++ ) {
	keywordVec.add("<a href='index.jsp?" + m.qs("id,s_field,s_keyword") + "&s_field=a.keyword&s_keyword=" + m.urlencode(keywords[i].trim()) + "'>" + keywords[i].trim() + "</a>");
}
info.put("keyword_conv", keywords.length > 0 ? m.join(", ", keywordVec.toArray()) : "");
info.put("status_conv", m.getItem(info.s("status"), post.statusList));
info.put("display_yn_conv", m.getItem(info.s("display_yn"), post.displayYn));
user.maskInfo(info);

//기록-개인정보조회
if("".equals(m.rs("mode")) && info.size() > 0 && !isBlindUser) _log.add("V", Menu.menuNm, info.size(), "이러닝 운영", info);

//업데이트-조회수//쿠키셋팅
String[] readArray = m.getCookie("READ").split("\\,");
if(!m.inArray("" + id, readArray)) {
	post.updateHitCount(id);
	String tmp = m.join(",", readArray);
	tmp = "".equals(tmp) ? "" + id : tmp + "," + id;
	m.setCookie("READ", tmp, 3600 * 24);
}

//로그등록-읽기
PostLogDao postLog = new PostLogDao(siteId);
postLog.log(userId, id, "read");

//목록-파일
DataSet files = file.getFileList(id, "post");
while(files.next()) {
	files.put("file_ext", file.getFileExt(files.s("filename")));
	files.put("filename_conv", m.urlencode(m.encode(files.s("filename"))));
	files.put("ext", file.getFileIcon(files.s("filename")));
	files.put("ek", m.encrypt(files.s("id")));
}

//이전글/다음글
DataSet pinfo = new DataSet();
DataSet ninfo = new DataSet();
post.appendWhere("a.status != -1");
post.appendSearch("a.category_id", m.rs("s_category_id"));
if(!"".equals(f.get("s_field"))) post.appendSearch(m.rs("s_field"), m.rs("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	Vector<String> v = new Vector<String>();
	v.add("a.subject LIKE '%" + m.rs("s_keyword") + "%'");
	v.add("a.content LIKE '%" + m.rs("s_keyword") + "%'");
	v.add("a.writer LIKE '%" + m.rs("s_keyword") + "%'");
	post.appendWhere("(" + m.join(" OR ", v.toArray()) + ")");
}
pinfo = post.getPrevPost(bid, info.i("thread"), info.s("depth"));
ninfo = post.getNextPost(bid, info.i("thread"), info.s("depth"));
if(pinfo.next()) {
	pinfo.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", pinfo.s("reg_date")));
	pinfo.put("comment_conv", pinfo.i("comm_cnt") > 0? "(" + pinfo.i("comm_cnt") + ")" : "" );
	pinfo.put("hit_conv", m.nf(pinfo.i("hit_cnt")));
	pinfo.put("recomm_conv", m.nf(pinfo.i("recomm_cnt")));
	pinfo.put("new_block", m.diffDate("H", pinfo.s("reg_date"), m.time("yyyyMMddHHmmss")) <= newHour);
	pinfo.put("subject", m.htmlToText(pinfo.s("subject")));
	pinfo.put("subject_conv", m.cutString(pinfo.s("subject"), 80));
	pinfo.put("user_nm_conv", pinfo.s("user_nm") + "(" + pinfo.s("login_id") + ")" );

	categoryName = binfo.b("category_yn") ? category.getName(categories, pinfo.s("category_id")) : "" ;
	pinfo.put("category_conv", !"".equals(categoryName) ? "[" + categoryName + "]" : "");
}
if(ninfo.next()) {
	ninfo.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", ninfo.s("reg_date")));
	ninfo.put("comment_conv", ninfo.i("comm_cnt") > 0? "(" + ninfo.i("comm_cnt") + ")" : "" );
	ninfo.put("hit_conv", m.nf(ninfo.i("hit_cnt")));
	ninfo.put("recomm_conv", m.nf(ninfo.i("recomm_cnt")));
	ninfo.put("new_block", m.diffDate("H", ninfo.s("reg_date"), m.time("yyyyMMddHHmmss")) <= newHour);
	ninfo.put("subject", m.htmlToText(ninfo.s("subject")));
	ninfo.put("subject_conv", m.cutString(ninfo.s("subject"), 80));
	ninfo.put("user_nm_conv", ninfo.s("user_nm") + "(" + ninfo.s("login_id") + ")" );

	categoryName = binfo.b("is_category") ? category.getName(categories, ninfo.s("category_id")) : "" ;
	ninfo.put("category_conv", !"".equals(categoryName) ? "[" + categoryName + "]" : "");
}

//출력
p.setLayout(ch);
p.setBody("board.read");
p.setVar("p_title", binfo.s("board_nm"));
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setVar("board", binfo);
p.setVar(info);
p.setLoop("categories", categories);
p.setLoop("files", files);

p.setVar("prev", pinfo);
p.setVar("next", ninfo);
p.display();

%>