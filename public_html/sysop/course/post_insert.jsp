<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(93, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String code = m.rs("code");
String mode = m.rs("mode");
if("".equals(code)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ClBoardDao board = new ClBoardDao();
ClPostDao post = new ClPostDao();
ClFileDao file = new ClFileDao();
CourseDao course = new CourseDao();
MCal mcal = new MCal();
WordFilterDao wordFilterDao = new WordFilterDao();

//폼체크
f.addElement("course_id", f.get("s_course_id"), "hname:'과정명', required:'Y'");
f.addElement("subject", null, "hname:'제목', required:'Y'");
f.addElement("writer", userName, "hname:'작성자', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
if("review".equals(code)) f.addElement("point", 5, "hname:'별점', required:'Y'");
//f.addElement("reg_date", m.time(), "hname:'등록일', required:'Y'");
f.addElement("reg_date", m.time("yyyy-MM-dd"), "hname:'등록일', required:'Y'");
f.addElement("display_yn", "Y", "hname:'노출여부'");

//변수
boolean managementBlock = "management".equals(m.rs("mode"));

//등록
if(m.isPost() && f.validate()) {

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
		m.jsAlert("비속어가 포함되어 등록할 수 없습니다.");
		return;
	}

	int newId = post.getSequence();

	DataSet info = board.query(
		" SELECT a.* "
		+ " FROM " + board.table + " a "
		+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " AND c.status != -1 "
			+ ("C".equals(userKind) ? " AND a.course_id IN (" + manageCourses + ") " : "")
		+ " WHERE a.course_id = " + f.getInt("course_id") + " AND a.code = '" + code + "'"
	);
	if(!info.next()) { m.jsError("해당 게시판 정보가 없습니다."); return; }

	post.item("id", newId);
	post.item("site_id", siteId);
	post.item("thread", post.getLastThread());
	post.item("depth", "A");
	post.item("course_id", f.getInt("course_id"));
	post.item("board_cd", info.s("code"));
	post.item("board_id", info.i("id"));
	post.item("user_id", userId);
	post.item("writer", f.get("writer"));
	post.item("subject", f.get("subject"));
	post.item("content", content);
	post.item("point", f.getInt("point"));
	post.item("public_yn", "Y");
	post.item("notice_yn", "N");
	post.item("secret_yn", "N");
	post.item("hit_cnt", 0);
	post.item("comm_cnt", 0);
	post.item("display_yn", f.get("display_yn"));
	post.item("proc_status", 0);
	post.item("mod_date", "");
	post.item("reg_date", m.time("yyyyMMdd", f.get("reg_date")) + f.get("reg_hour") + f.get("reg_min") + "00");
//	post.item("reg_date", m.time("yyyyMMddHHmmss", f.get("reg_date")));
	post.item("status", 1);

	if(!post.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	//갱신
	file.updateTempFile(f.getInt("temp_id"), newId);

	m.jsReplace("post_list.jsp?" + m.qs(), "parent");
	return;
}

//출력
p.setBody("course.post_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("board_nm", m.getItem(code, board.types));
p.setVar("post_id", m.getRandInt(-2000000, 1990000));
p.setVar("management_block", managementBlock);
p.setVar("recomm_type_block", "review".equals(code));

p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes());

p.setLoop("course_list", course.getCourseList(siteId, userId, userKind, "N"));
p.setLoop("display_yn", m.arr2loop(post.displayYn));
p.display();

%>