<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
int count = m.ri("cnt") > 0 ? m.ri("cnt") : 5;
int strlen = m.ri("strlen") > 0 ? m.ri("strlen") : 30;

DataSet siteconfig = SiteConfig.getArr(new String[] {"target_"});

//객체
ClPostDao clPost = new ClPostDao();
ClBoardDao clBoard = new ClBoardDao();
CourseDao course = new CourseDao();
CourseTargetDao courseTarget = new CourseTargetDao();

//목록
DataSet list = clPost.query(
	"SELECT a.*, c.course_nm "
	+ " FROM " + clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id AND b.code = 'review' "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId
	+ " WHERE a.display_yn = 'Y' AND a.status = 1 "
	+ ("N".equals(siteconfig.s("target_review_yn")) ? (" AND (c.target_yn = 'N'" + (!"".equals(userGroups) ? " OR EXISTS (SELECT 1 FROM " + courseTarget.table + " WHERE course_id = c.id AND group_id IN (" + userGroups + "))" : "") + ")") : "")
	+ " ORDER BY a.thread, a.depth, a.id DESC "
	, count
);
String on = "<img src='/html/images/common/star_on.jpg'>";
String off = "<img src='/html/images/common/star_off.jpg'>";

while(list.next()) {
	list.put("subject_conv", m.cutString(list.s("subject"), strlen));
	list.put("point", m.repeatString(on , list.i("point")) + m.repeatString(off , 5 - list.i("point")));
	list.put("writer_conv", "Y".equals(SiteConfig.s("masking_yn")) ? m.masking(list.s("writer")) : list.s("writer"));
	list.put("content_conv", m.htt(list.s("content")));
}

//출력
p.setLayout(null);
p.setBody("inc.review_list");
p.setLoop("list", list);
p.display();

%>