<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(93, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();
UserDao user = new UserDao();
CourseDao course = new CourseDao();


//폼체크
f.addElement("s_course", null, null);
f.addElement("s_proc_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(
	clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id AND b.code = 'qna' "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " INNER JOIN " + course.table + " c ON "
		+ " a.course_id = c.id AND c.status = 1 AND c.site_id = " + siteId + " "
);
lm.setFields("a.*, u.login_id, c.course_nm");
lm.addWhere("a.status != -1");
lm.addWhere("a.depth = 'A'");
lm.addSearch("a.course_id", f.get("s_course"));
lm.addSearch("a.proc_status", f.get("s_proc_status"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("u.login_id, a.writer, a.subject, a.content, c.course_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.thread, a.depth, a.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("new_block", m.diffDate("H", list.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("hit_cnt_conv", m.nf(list.getInt("hit_cnt")));
	list.put("proc_status_conv", m.getItem(list.s("proc_status"), clPost.procStatusList));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "과정QNA관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "course_nm=>과정명", "subject=>제목", "writer=>작성자", "user_id=>회원아이디", "reg_date_conv=>등록일", "proc_status_conv=>답변상태" }, "과정QNA관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}


//출력
p.setBody("qna.qna_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setLoop("proc_status_list", m.arr2loop(clPost.procStatusList));
p.setLoop("courses", course.getCourseList(siteId));
p.display();

%>