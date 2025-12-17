<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > Q&A 탭에서, 교수자가 답변을 작성/수정하면 질문 글의 상태(proc_status)도 함께 갱신해야 합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
int postId = m.ri("post_id");
if(0 == courseId || 0 == postId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id, post_id가 필요합니다.");
	result.print();
	return;
}

String answerContent = m.rs("content");
if("".equals(answerContent)) {
	result.put("rst_code", "1002");
	result.put("rst_message", "content(답변 내용)가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseDao course = new CourseDao();
ClBoardDao board = new ClBoardDao(siteId);
ClPostDao post = new ClPostDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 Q&A에 답변할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet cinfo = course.find("id = " + courseId + " AND site_id = " + siteId + " AND status != -1");
if(!cinfo.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 과목이 없습니다.");
	result.print();
	return;
}

DataSet binfo = board.find("course_id = " + courseId + " AND site_id = " + siteId + " AND code = 'qna' AND status = 1");
if(!binfo.next()) {
	result.put("rst_code", "4041");
	result.put("rst_message", "Q&A 게시판 정보가 없습니다.");
	result.print();
	return;
}

//왜: base64 이미지는 DB에 누적되면 용량 폭증/오류가 나기 쉽습니다.
if(-1 < answerContent.indexOf("<img") && -1 < answerContent.indexOf("data:image/") && -1 < answerContent.indexOf("base64")) {
	result.put("rst_code", "1101");
	result.put("rst_message", "이미지는 첨부파일로 업로드해 주세요.");
	result.print();
	return;
}
int bytes = answerContent.replace("\r\n", "\n").getBytes("UTF-8").length;
if(60000 < bytes) {
	result.put("rst_code", "1102");
	result.put("rst_message", "내용은 60000바이트를 초과할 수 없습니다. (현재 " + bytes + "바이트)");
	result.print();
	return;
}

DataSet qinfo = post.find(
	"id = " + postId + " AND site_id = " + siteId + " AND course_id = " + courseId + " AND board_id = " + binfo.i("id") + " AND status != -1"
);
if(!qinfo.next()) {
	result.put("rst_code", "4042");
	result.put("rst_message", "해당 질문 글이 없습니다.");
	result.print();
	return;
}

String now = m.time("yyyyMMddHHmmss");

//답변 글(동일 thread, depth='AA')을 만들거나 갱신합니다.
int answerId = 0;
DataSet ainfo = post.find("thread = " + qinfo.s("thread") + " AND depth = 'AA' AND status != -1", "*", "id DESC", 1);
if(ainfo.next()) {
	answerId = ainfo.i("id");
	post.item("writer", userName);
	post.item("content", answerContent);
	post.item("mod_date", now);
	post.item("status", 1);
	if(!post.update("id = " + answerId + "")) {
		result.put("rst_code", "2000");
		result.put("rst_message", "답변 저장 중 오류가 발생했습니다.");
		result.print();
		return;
	}
} else {
	answerId = post.getSequence();
	post.item("id", answerId);
	post.item("site_id", siteId);
	post.item("course_id", courseId);
	post.item("board_cd", "qna");
	post.item("board_id", binfo.i("id"));
	post.item("course_user_id", qinfo.i("course_user_id"));
	post.item("thread", qinfo.i("thread"));
	post.item("depth", "AA");
	post.item("user_id", userId);
	post.item("writer", userName);
	post.item("subject", qinfo.s("subject"));
	post.item("content", answerContent);
	post.item("notice_yn", "N");
	post.item("mod_date", now);
	post.item("reg_date", now);
	post.item("proc_status", 0);
	post.item("status", 1);
	if(!post.insert()) {
		result.put("rst_code", "2000");
		result.put("rst_message", "답변 저장 중 오류가 발생했습니다.");
		result.print();
		return;
	}
}

//질문 글 상태를 "답변완료"로 업데이트
post.execute(
	" UPDATE " + post.table
	+ " SET proc_status = 1, mod_date = '" + now + "'"
	+ " WHERE id = " + postId
);

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", answerId);
result.print();

%>

