<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();
ClFileDao clFile = new ClFileDao();

int boardId = clBoard.getOneInt("SELECT id FROM " + clBoard.table + " WHERE course_id = " + courseId + " AND board_type = 4");

if(boardId == 0) { m.jsError(_message.get("alert.board.nodata")); return; }

//글쓰기 여부????
boolean isWrite = true;
//if(!isWrite) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

f.addElement("subject", null, "hname:'제목', required:'Y'");
f.addElement("point", null, "hname:'별점', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
//f.addElement("public_yn", "Y", "hname:'공개여부', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	int newId = clPost.getSequence();

	clPost.item("id", newId);
	clPost.item("site_id", siteId);
	clPost.item("course_id", courseId);
	clPost.item("board_cd", "review");
	clPost.item("board_id", boardId);
	clPost.item("course_user_id", cuid);
	clPost.item("thread", clPost.getLastThread());
	clPost.item("depth", "A");
	clPost.item("user_id", userId);
	clPost.item("writer", userName);
	clPost.item("subject", f.get("subject"));
	clPost.item("content", f.get("content"));
	clPost.item("point", f.getInt("point"));
	clPost.item("public_yn", "Y");
	clPost.item("notice_yn", "N");
	clPost.item("hit_cnt", 0);
	clPost.item("comm_cnt", 0);
	clPost.item("display_yn", "Y");
	clPost.item("mod_date", m.time("yyyyMMddHHmmss"));
	clPost.item("reg_date", m.time("yyyyMMddHHmmss"));
	clPost.item("status", 1);

	if(!clPost.insert()) { m.jsAlert(_message.get("alert.common.error_insert")); return; }

	m.jsReplace("review.jsp?cuid=" + cuid, "parent");
	return;
}

//출력
p.setLayout(ch);
p.setBody("classroom.review_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("is_write", isWrite);
p.setVar("active_epil", "select");
p.display();

%>