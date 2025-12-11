<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(93, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
String code = m.rs("code");
String mode = m.rs("mode");
if("".equals(code) || id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ClBoardDao board = new ClBoardDao();
ClPostDao post = new ClPostDao();
CourseDao course = new CourseDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();
MCal mcal = new MCal();
WordFilterDao wordFilterDao = new WordFilterDao();

DataSet info = post.query(
	"SELECT a.*, b.board_nm, b.board_type, c.course_nm "
	+ " FROM " + post.table + " a "
	+ " INNER JOIN " + board.table + " b ON a.board_id = b.id "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND b.course_id = c.id "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE a.status != -1 AND a.id = " + id + " "
	+ ("C".equals(userKind) ? " AND a.course_id IN (" + manageCourses + ") " : "")
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
p.setVar(info.s("board_type") + "_type_block", true);

//변수
boolean managementBlock = "management".equals(m.rs("mode"));

//폼체크
//f.addElement("course_id", info.i("course_id"), "hname:'과정명', required:'Y'");
f.addElement("writer", info.s("writer"), "hname:'작성자', required:'Y'");
f.addElement("subject", info.s("subject"), "hname:'제목', required:'Y'");
f.addElement("content", null, "hname:'내용', allowiframe:'Y', allowhtml:'Y'");
f.addElement("notice_yn", "Y".equals(info.s("notice_yn")) ? "Y" : "N", "hname:'공지글여부'");
if("review".equals(code)) f.addElement("point", info.i("point"), "hname:'별점', required:'Y'");
//f.addElement("reg_date", info.s("reg_date"), "hname:'등록일'");
f.addElement("reg_date", m.time("yyyy-MM-dd", info.s("reg_date")), "hname:'등록일', required:'Y'");
f.addElement("reg_hour", m.time("HH", info.s("reg_date")), "hname:'등록일(시)'");
f.addElement("reg_min", m.time("mm" ,info.s("reg_date")), "hname:'등록일(분)'");
f.addElement("display_yn", info.s("display_yn"), "hname:'노출여부'");

//수정
if(m.isPost() && f.validate()) {
	/*
	//과정수정
	if(info.i("course_id") != f.getInt("course_id")) {
		DataSet binfo = board.query(
			" SELECT a.* "
			+ " FROM " + board.table + " a "
			+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " AND c.status != -1 "
			+ " WHERE a.course_id = " + f.getInt("course_id") + " AND a.code = '" + code + "'"
			+ ("C".equals(userKind) ? " AND a.course_id IN (" + manageCourses + ") " : "")
		);
		if(!binfo.next()) { m.jsError("해당 게시판 정보가 없습니다."); return; }
		post.item("course_id", f.getInt("course_id"));
		post.item("board_id", binfo.i("id"));

		if(!post.update("thread = '" + info.s("thread") + "'")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }
		post.clear();
	}
	*/

	String content = f.get("content");
	//제한-이미지URI
	if(-1 < content.indexOf("<img") && -1 < content.indexOf("data:image/") && -1 < content.indexOf("base64")) {
		m.jsAlert("이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}

	//제한-용량
	int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(60000 < bytes) {
		m.jsAlert("내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes + "바이트)");
		return;
	}

	//제한-비속어
	if(wordFilterDao.check(f.get("subject")) || wordFilterDao.check(content)) {
		m.jsAlert("비속어가 포함되어 수정할 수 없습니다.");
		return;
	}

	post.item("writer", f.get("writer"));
	post.item("subject", f.get("subject"));
	post.item("content", content);
	post.item("mod_date", m.time("yyyyMMddHHmmss"));
	post.item("point", f.getInt("point"));
	post.item("display_yn", f.get("display_yn"));
//	post.item("reg_date", f.get("reg_date"));
	post.item("reg_date", m.time("yyyyMMdd", f.get("reg_date")) + f.get("reg_hour") + f.get("reg_min") + "00");
	if(!post.update("id = " + id + "")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("post_view.jsp?" + m.qs(), "parent");
	return;
}
info.put("content", m.htt(info.s("content")));

//출력
p.setBody("course.post_insert");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);
p.setVar("post_id", id);
p.setVar("management_block", managementBlock);

p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes());

p.setLoop("course_list", course.getCourseList(siteId, userId, userKind, "N"));
p.setLoop("display_yn", m.arr2loop(post.displayYn));
p.display();

%>