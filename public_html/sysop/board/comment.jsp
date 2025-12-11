<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
//if(!(Menu.accessible("BOARD", authId))) { m.jsError("접근 권한이 없습니다."); return; }

//폼입력
String md = m.rs("md", "post");
int mid = m.ri("mid", 0);
String mode = m.rs("mode");

//객체
CommentDao comment = new CommentDao();
UserDao user = new UserDao();

BoardDao board = new BoardDao();
PostDao post = new PostDao();
GroupDao group = new GroupDao();

WebtvDao webtv = new WebtvDao();
WordFilterDao wordFilterDao = new WordFilterDao();

//처리
if(m.isPost()) {
	//등록
	if("reg".equals(mode)) {
		//폼체크
		f.addElement("content", null, "hname:'덧글', required:'Y'");

		if(f.validate()) {
			String content = f.get("content");
			//제한-용량
			int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
			if(60000 < bytes) { m.jsAlert("내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes + "바이트)"); return; }

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
			if(!comment.insert()) {	m.jsAlert("등록하는 중 오류가 발생하였습니다."); return; }
		}

	//수정
	} else if("mod".equals(mode)) {
		//기본키
		int id = m.ri("id", 0);
		if(id == 0) { m.jsAlert("아이디는 반드시 지정해야 합니다."); return; }

		String content = f.get("content");
		//제한-용량
		int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
		if(60000 < bytes) { m.jsAlert("내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes + "바이트)"); return; }

		//제한-비속어
		if(wordFilterDao.check(content)) {
			m.jsAlert("비속어가 포함되어 수정할 수 없습니다.");
			return;
		}

		//정보
		DataSet info = comment.find("id = " + id + "");
		if(!info.next()) { m.jsAlert("해당 정보가 없습니다."); return;	}

		comment.item("content", content);
		comment.item("mod_date", m.time("yyyyMMddHHmmss"));

		if(!comment.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생하였습니다."); return; }
	}

	//모듈별처리
	if("post".equals(md)) post.updateCommCount(mid);
	else if("webtv".equals(md)) webtv.updateCommCount(mid);

	//이동
	m.jsReplace("comment.jsp?" + m.qs("id,mode"), "parent");
	return;
}

//삭제
if("del".equals(mode)) {
	//기본키
	int id = m.ri("id", 0);
	if(id == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	//정보
	DataSet info = comment.find("module = '" + md + "' AND module_id = " + mid + " AND id = " + id + " AND status = 1");
	if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

	//삭제
	comment.item("status", -1);
	if(!comment.update("module = '" + md + "' AND module_id = " + mid + " AND id = " + id + " AND status = 1")) { m.jsError("삭제하는 중 오류가 발생하였습니다."); return; }

	//이동
	m.jsReplace("comment.jsp?" + m.qs("id,mode"), "parent");
	return;
}

//갱신
if("post".equals(md)) post.updateCommCount(mid);
else if("webtv".equals(md)) webtv.updateCommCount(mid);

//목록
ListManager lm = new ListManager(jndi);
//lm.d(out);
lm.setRequest(request);
lm.setListNum(20);
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
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", list.s("reg_date")));
	//list.put("content_conv", m.nl2br(m.htmlToText(list.s("content"))));
	//list.put("content_conv", m.htmlToText(list.s("content")));
	list.put("content_conv", m.nl2br(m.htt(list.s("content"))));
	list.put("content_conv2", m.addSlashes(list.s("content")));
}

//출력
p.setLayout("blank");
p.setBody("board.comment");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());
p.setVar("total_num", m.nf(lm.getTotalNum()));

p.setVar("writer", userName);
p.display();

%>