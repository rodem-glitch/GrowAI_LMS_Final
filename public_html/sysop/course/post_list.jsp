<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(93, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String code = m.rs("code");
String mode = m.rs("mode");
if("".equals(code)) { m.jsReplace("post_list.jsp?code=qna&" + m.qs()); return; }

//객체
ClPostDao post = new ClPostDao();
ClBoardDao board = new ClBoardDao();
CourseDao course = new CourseDao();
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();

//변수
boolean managementBlock = "management".equals(m.rs("mode"));

//정보
DataSet cinfo = new DataSet();
if(managementBlock) {
	cinfo = course.find(
		"id = " + m.rs("s_course_id") + " AND site_id = " + siteId + " AND status != -1"
		+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
	);
	if(!cinfo.next()) { m.jsAlert("해당 과정정보가 없습니다."); return; }
}

//폼체크
f.addElement("s_course_id", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
if(managementBlock) f.addElement("code", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setTable(
	post.table + " a "
	+ " INNER JOIN " + board.table + " b ON a.board_id = b.id "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND b.course_id = c.id AND c.site_id = a.site_id "
	+ " LEFT JOIN " + user.table + " u ON u.site_id = a.site_id AND a.user_id = u.id AND u.status != -1 "
);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setFields("a.*, b.board_nm, b.code, c.course_nm, u.user_nm, u.login_id");
lm.addWhere("a.site_id = " + siteId);
lm.addWhere("a.status > -1");
lm.addWhere("a.depth = 'A'");
lm.addWhere("b.code = '" + code + "'");
if(deptManagerBlock) lm.addWhere("u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ")");
lm.addSearch("a.course_id", m.rs("s_course_id"));
if("C".equals(userKind)) lm.addWhere("a.course_id IN (" + manageCourses + ")");
if(!"".equals(m.rs("s_field"))) lm.addSearch(m.rs("s_field"), m.rs("s_keyword"), "LIKE");
else lm.addSearch("a.subject, a.content, a.writer", m.rs("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.thread ASC, a.depth ASC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));

	list.put("hit_cnt_conv", m.nf(list.i("hit_cnt")));

	list.put("subject_conv", m.cutString(list.s("subject"), 50));
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 26));
	
	list.put("user_id", list.i("user_id") > 0 ? list.s("user_id") : "");
	list.put("login_id_conv", "".equals(list.s("login_id")) ? "-" : list.s("login_id"));

	list.put("new_block", m.diffDate("H", list.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
	list.put("status_conv", 1 == list.i("status") ? "정상" : "중지");
	list.put("proc_status_conv", m.getItem(list.s("proc_status"), post.procStatusList));
	list.put("display_yn_conv", m.getItem(list.s("display_yn"), post.displayYn));
	user.maskInfo(list);
}

//기록-개인정보조회
if(list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), inquiryPurpose, list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), inquiryPurpose, list);

	ExcelWriter ex = new ExcelWriter(response, "과정게시판관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, "review".equals(code)
		? new String[] { "__ord=>No", "course_nm=>과정명", "board_nm=>게시판명", "subject=>제목", "content=>내용", "login_id=>로그인ID", "user_nm=>작성자", "hit_cnt=>조회수", "point=>별점", "reg_date_conv=>등록일", "status=>상태", "proc_status_conv=>답변상태" }
		: new String[] { "__ord=>No", "course_nm=>과정명", "board_nm=>게시판명", "subject=>제목", "content=>내용", "login_id=>로그인ID", "user_nm=>작성자", "hit_cnt=>조회수", "reg_date_conv=>등록일", "status=>상태", "proc_status_conv=>답변상태" }
	, "과정게시판관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("course.post_list");
p.setVar("p_title"
	, !managementBlock
	? "과정게시판관리"
	: "<span style='color:#666666'>[" + cinfo.s("year") + "년/" + cinfo.s("step") + "기]</span> <span style='color:#4C5BA9'>" + cinfo.s("course_nm") + "</span>"
);
p.setVar("list_query", m.qs("id,bid,code"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("list_total", lm.getTotalString());
p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setLoop("course_list", course.getCourseList(siteId, userId, userKind, "N"));
p.setLoop("board_list", m.arr2loop(board.baseBoardNames));
if(managementBlock) p.setLoop("boards", board.find("course_id = " + f.get("s_course_id") + " AND status = 1"));
p.setVar("management_block", managementBlock);
p.setVar(code + "_block", true);
p.setVar("code", code);
p.display();

%>