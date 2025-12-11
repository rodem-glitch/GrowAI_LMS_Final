<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
String code = !"".equals(m.rs("code")) ? m.rs("code") : "notice";
String ord = !"".equals(m.rs("ord")) ? m.rs("ord") : "a.thread, a.depth";
int count = m.ri("cnt") > 0 ? m.ri("cnt") : 5;
int strlen = m.ri("strlen") > 0 ? m.ri("strlen") : 30;
int contlen = m.ri("contlen") > 0 ? m.ri("contlen") : 100;
int newHour = m.ri("newhour") > 0 ? m.ri("newhour") : 24;
int cid = m.ri("cid"); //과정의 cid와 중복되어 오류가 생길 수 있음
if(m.ri("bcid") > 0) cid = m.ri("bcid");
boolean useNotice = 1 == m.ri("use_notice");

//객체
BoardDao board = new BoardDao();
PostDao post = new PostDao();
FileDao file = new FileDao();
CategoryDao category = new CategoryDao();
UserDao user = new UserDao();

//정보-게시판
DataSet binfo = board.find("code = ? AND site_id = ? AND status = 1", new Object[] { code, siteId });
if(!binfo.next()) return;

//목록
DataSet list = post.query(
	"SELECT a.*, b.board_nm, b.code, b.board_type, f.filename, c.category_nm, u.login_id "
	+ " FROM " + post.table + " a "
	+ " INNER JOIN " + board.table + " b ON "
		+ " a.board_id = b.id AND b.code = '" + code + "' AND b.site_id = " + siteId + " "
	+ " LEFT JOIN " + file.table + " f ON f.module = 'post' AND f.module_id = a.id AND f.main_yn = 'Y' "
	+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " WHERE a.display_yn = 'Y' AND a.status = 1 AND a.depth = 'A' "
	+ (cid > 0 ? " AND a.category_id = " + cid + " " : "")
	+ " ORDER BY " + ("faq".equals(binfo.s("board_type")) ? "a.sort asc," : "") + (useNotice ? "a.notice_yn desc, " : "") + ord
	, count
);
while(list.next()) {
	list.put("subject_conv", m.cutString(list.s("subject"), strlen));
	list.put("content_conv", m.cutString(list.s("content"), contlen));
	list.put("reg_date_conv", m.time(_message.get("format.date.dot"), list.s("reg_date")));
	list.put("reg_date_conv2", m.time(_message.get("format.datemonth.dot"), list.s("reg_date")));
	list.put("new_block", m.diffDate("H", list.s("reg_date"), m.time("yyyyMMddHHmmss")) <= newHour);
	list.put("read_block", !list.b("secret_yn") || (list.b("secret_yn") && list.i("user_id") == userId));
	
	list.put("writer_conv", "Y".equals(SiteConfig.s("masking_yn")) ? m.masking(list.s("writer")) : list.s("writer"));

	//이미지
	if(!"".equals(list.s("filename"))) {
		list.put("file_url", m.getUploadUrl(list.s("filename")));
	} else {
		list.put("file_url", "/common/images/default/noimage_gallery.jpg");
	}
}

//출력
p.setLayout(null);
p.setBody("main.post_list");
p.setLoop("list", list);
p.setVar("board", binfo);
p.setVar("board_type_" + binfo.s("board_type"), true);
p.setVar("type_" + code, true);
p.display();

%>