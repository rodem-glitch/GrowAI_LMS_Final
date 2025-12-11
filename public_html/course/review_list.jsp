<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
ClPostDao clPost = new ClPostDao();
ClBoardDao clBoard = new ClBoardDao();
CourseDao course = new CourseDao();
CourseTargetDao courseTarget = new CourseTargetDao();

//폼체크
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id AND b.code = 'review' "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " "
);
lm.setFields("a.*, c.course_nm, c.step, c.year");
lm.addWhere("a.display_yn = 'Y'");
lm.addWhere("a.status = 1");

//학습그룹이 지정된 경우 검색 조건 추가
if("N".equals(siteconfig.s("target_review_yn"))) lm.addWhere("(c.target_yn = 'N'" + (!"".equals(userGroups) ? " OR EXISTS (SELECT 1 FROM " + courseTarget.table + " WHERE course_id = c.id AND group_id IN (" + userGroups + "))" : "") + ")");


String sField = f.get("s_field", "");
String allowFields = "a.subject,a.content,a.writer";
if(!m.inArray(sField, allowFields)) sField = "";
if(!"".equals(sField)) lm.addSearch(sField, f.get("s_keyword"), "LIKE");
else lm.addSearch(allowFields, f.get("s_keyword"), "LIKE");
lm.setOrderBy("a.thread, a.depth, a.id DESC");

DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("subject_conv", m.cutString(list.s("subject"), 80));
	list.put("new_block", m.diffDate("H", list.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
	list.put("reg_date_conv", m.time(_message.get("format.date.dot"), list.s("reg_date")));
	list.put("writer_conv", "Y".equals(SiteConfig.s("masking_yn")) ? m.masking(list.s("writer")) : list.s("writer"));
}

//출력
p.setLayout(ch);
p.setBody("course.review_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());

p.display();

%>