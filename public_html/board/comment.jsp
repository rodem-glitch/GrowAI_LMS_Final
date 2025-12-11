<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//폼입력
String md = m.rs("md", "post");
int mid = m.ri("mid");
String mode = m.rs("mode");

//객체
CommentDao comment = new CommentDao();
UserDao user = new UserDao();

BoardDao board = new BoardDao();
PostDao post = new PostDao();
GroupDao group = new GroupDao();

WebtvDao webtv = new WebtvDao();
WordFilterDao wordFilterDao = new WordFilterDao();

//변수
boolean isWrite = 0 < userId;
boolean isAdmin = 0 < userId && "S".equals(userKind);

//모듈별제한
if("post".equals(md)) {
	DataSet minfo = post.query(
		" SELECT a.*, b.private_yn, b.admin_idx "
		+ " FROM " + post.table + " a "
		+ " INNER JOIN " + board.table + " b ON a.board_id = b.id AND b.comment_yn = 'Y' "
		+ " WHERE a.id = ? AND a.status = 1 AND a.display_yn = 'Y' "
		, new Object[] { mid }
	);
	if(!minfo.next()) { m.jsError(_message.get("alert.post.nodata")); return; }
	if(minfo.b("private_yn") && userId != minfo.i("user_id")) { m.jsError(_message.get("alert.post.nodata")); return; }
	isWrite = board.accessible("comm", minfo.i("board_id"), userGroups, userKind);
	isAdmin = 0 != userId && ("S".equals(userKind) || Menu.accessible(80, userId, userKind, false) || -1 < minfo.s("admin_idx").indexOf("|" + userId + "|"));
} else if("webtv".equals(md)) {
	DataSet minfo = webtv.find("id = ? AND comment_yn = 'Y' AND status = 1", new Object[] { mid });
	if(!minfo.next()) { m.jsError(_message.get("alert.webtv.nodata")); return; }
}

//처리
if(m.isPost()) {
	//등록
	if("reg".equals(mode)) {
		//폼체크
		f.addElement("content", null, "hname:'댓글', required:'Y'");

		if(f.validate()) {
			String content = f.get("content");
			//제한-용량
			int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
			if(60000 < bytes) { m.jsAlert(_message.get("alert.board.over_capacity", new String[] {"maximum=>60000", "bytes=>" + bytes})); return; }

			//제한-비속어
			if(wordFilterDao.check(content)) {
				m.jsAlert("비속어가 포함되어 등록할 수 없습니다.");
				return;
			}

			int newId = comment.getSequence();
			comment.item("id", newId);
			comment.item("site_id", siteId);
			comment.item("module", md);
			comment.item("module_id", mid);
			comment.item("user_id", userId);
			comment.item("writer", userName);
			comment.item("content", content);
			comment.item("mod_date", "");
			comment.item("reg_date", m.time("yyyyMMddHHmmss"));
			comment.item("status", 1);
			if(!comment.insert()) {	m.jsAlert(_message.get("alert.common.error_insert")); return; }
		}
	}

	//모듈별처리
	if("post".equals(md)) post.updateCommCount(mid);
	else if("webtv".equals(md)) webtv.updateCommCount(mid);

	//이동
	m.jsReplace("comment.jsp?" + m.qs("mode"), "parent");
	return;
}

//삭제
if("del".equals(mode)) {
	//기본키
	int id = m.ri("id", 0);
	if(id == 0) { m.jsAlert(_message.get("alert.common.required_key")); return; }

	//정보
	DataSet info = comment.find("module = ? AND module_id = ? AND id = ? AND status = 1", new Object[] { md, mid, id });
	if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

	//제한
	if(userId != info.i("user_id") && !isAdmin) { m.jsError(_message.get("alert.common.permission_delete")); return; }

	//삭제
	comment.item("status", -1);
	if(!comment.update("module = '" + md + "' AND module_id = " + mid + " AND id = " + id + " AND status = 1")) { m.jsError(_message.get("alert.common.error_delete")); return; }

	//이동
	m.jsReplace("comment.jsp?" + m.qs("id,mode"));
	return;
}

//갱신
if("post".equals(md)) post.updateCommCount(mid);
else if("webtv".equals(md)) webtv.updateCommCount(mid);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	comment.table + " a "
	+ " LEFT JOIN " + user.table + " b ON a.user_id = b.id"
);
lm.setFields("a.*, b.login_id, b.user_kind");
lm.addWhere("a.status = 1");
lm.addWhere("a.module = '" + md + "'");
lm.addWhere("a.module_id = " + mid);
lm.setOrderBy("a.reg_date DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", m.time(_message.get("format.datetime.dot"), list.s("reg_date")));
	list.put("content_conv", m.nl2br(m.htt(list.s("content"))));
	list.put("content_conv2", m.addSlashes(list.s("content")));
	list.put("mod_block", userId == list.i("user_id") || isAdmin);

	list.put("writer_conv", "Y".equals(SiteConfig.s("masking_yn")) ? m.masking(list.s("writer")) : list.s("writer"));
}

//출력
p.setLayout("blank");
//p.setBody("board." + skin + "." + btype + (!"".equals(status) ? "_" + status : ""));
p.setBody("board.comment");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());
p.setVar("total_num", m.nf(lm.getTotalNum()));

p.setVar("admin_block", isAdmin);
p.setVar("write_block", isWrite);
p.display(out);

%>