<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
NoticeDao notice = new NoticeDao();

//정보
DataSet info = notice.find("id = " + id + " AND status != -1");
if(!info.next()) { m.jsError("해당 게시물이 없습니다."); return; }
info.put("reg_date_conv", m.time("yyyy.MM.dd", info.s("reg_date")));
info.put("mod_date_block", !"".equals(info.s("mod_date")));
info.put("mod_date_conv", m.time("yyyy.MM.dd", info.s("mod_date")));
info.put("hit_conv", m.nf(info.i("hit_cnt")));
info.put("new_block", m.diffDate("H", info.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
info.put("category_conv", m.getItem(info.s("category"), notice.categories));

Vector<String> keywordVec = new Vector<String>();
String[] keywords = !"".equals(info.s("keyword"))? info.s("keyword").split("\\,") : new String[] {};
for(int i = 0; i < keywords.length; i++ ) {
	keywordVec.add("<a href='index.jsp?" + m.qs("id,s_field,s_keyword") + "&s_field=a.keyword&s_keyword=" + m.urlencode(keywords[i].trim()) + "'>" + keywords[i].trim() + "</a>");
}
info.put("keyword_conv", keywords.length > 0 ? m.join(", ", keywordVec.toArray()) : "");
info.put("status_conv", m.getItem(info.s("status"), notice.statusList));

//업데이트-조회수//쿠키셋팅
String[] readArray = m.getCookie("NOTICEREAD").split("\\,");
if(!m.inArray("" + id, readArray)) {
	notice.updateHitCount(id);
	String tmp = m.join(",", readArray);
	tmp = "".equals(tmp) ? "" + id : tmp + "," + id;
	m.setCookie("NOTICEREAD", tmp, 3600 * 24);
}

//로그등록-읽기
//PostLogDao postLog = new PostLogDao(siteId);
//postLog.log(userId, id, "read");

//이전글/다음글
DataSet pinfo = new DataSet();
DataSet ninfo = new DataSet();
notice.appendWhere("a.status = 1");
notice.appendSearch("a.category", m.rs("s_category"));
if(!"".equals(f.get("s_field"))) notice.appendSearch(m.rs("s_field"), m.rs("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	Vector<String> v = new Vector<String>();
	v.add("a.subject LIKE '%" + m.rs("s_keyword") + "%'");
	v.add("a.content LIKE '%" + m.rs("s_keyword") + "%'");
	notice.appendWhere("(" + m.join(" OR ", v.toArray()) + ")");
}
pinfo = notice.getPrevPost(info.i("id"));
ninfo = notice.getNextPost(info.i("id"));
if(pinfo.next()) {
	pinfo.put("reg_date_conv", m.time("yyyy.MM.dd", pinfo.s("reg_date")));
	pinfo.put("hit_conv", m.nf(pinfo.i("hit_cnt")));
	pinfo.put("new_block", m.diffDate("H", pinfo.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
	pinfo.put("subject", m.htmlToText(pinfo.s("subject")));
	pinfo.put("subject_conv", m.cutString(pinfo.s("subject"), 80));
	pinfo.put("category_conv", m.getItem(pinfo.s("category"), notice.categories));
}
if(ninfo.next()) {
	ninfo.put("reg_date_conv", m.time("yyyy.MM.dd", ninfo.s("reg_date")));
	ninfo.put("hit_conv", m.nf(ninfo.i("hit_cnt")));
	ninfo.put("new_block", m.diffDate("H", ninfo.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
	ninfo.put("subject", m.htmlToText(ninfo.s("subject")));
	ninfo.put("subject_conv", m.cutString(ninfo.s("subject"), 80));
	ninfo.put("category_conv", m.getItem(ninfo.s("category"), notice.categories));
}

//출력
p.setLayout(ch);
p.setBody("notice.notice_read");
p.setVar("p_title", "서비스 공지사항");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setVar(info);
p.setLoop("categories", m.arr2loop(notice.categories));

p.setVar("prev", pinfo);
p.setVar("next", ninfo);
p.display();

%>