<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과제 통합관리 화면에서 과목 구분 없이 제출 목록을 한 번에 확인해야 합니다.
//- 페이지/필터 영향을 받지 않도록 서버에서 통합 리스트를 제공합니다.

CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseUserDao courseUser = new CourseUserDao();
HomeworkDao homework = new HomeworkDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();
UserDao user = new UserDao();

String keyword = m.rs("s_keyword");
String safeKeyword = m.replace(keyword, "'", "''");
String startDate = m.rs("start_date");
String endDate = m.rs("end_date");
String status = m.rs("status"); // unconfirmed/confirmed
int pageNo = m.ri("page", 1);
int pageSize = m.ri("page_size", 20);
if(pageNo < 1) pageNo = 1;
if(pageSize != 20 && pageSize != 50 && pageSize != 100) pageSize = 20;
int offset = (pageNo - 1) * pageSize;

String joinTutor = "";
if(!isAdmin) {
	joinTutor = " INNER JOIN " + courseTutor.table + " ct ON ct.course_id = c.id "
		+ " AND ct.user_id = " + userId + " AND ct.type = 'major' AND ct.site_id = " + siteId + " ";
}

String keywordWhere = "";
if(!"".equals(safeKeyword)) {
	keywordWhere = " AND (h.homework_nm LIKE '%" + safeKeyword + "%' "
		+ " OR c.course_nm LIKE '%" + safeKeyword + "%' "
		+ " OR u.user_nm LIKE '%" + safeKeyword + "%' "
		+ " OR u.login_id LIKE '%" + safeKeyword + "%') ";
}

String dateWhere = "";
if(!"".equals(startDate)) {
	dateWhere += " AND hu.reg_date >= '" + m.time("yyyyMMdd", startDate) + "000000' ";
}
if(!"".equals(endDate)) {
	dateWhere += " AND hu.reg_date <= '" + m.time("yyyyMMdd", endDate) + "235959' ";
}

String statusWhere = "";
if("unconfirmed".equals(status)) {
	statusWhere = " AND (hu.confirm_yn IS NULL OR hu.confirm_yn != 'Y') ";
} else if("confirmed".equals(status)) {
	statusWhere = " AND hu.confirm_yn = 'Y' ";
}

int totalCount = homeworkUser.getOneInt(
	" SELECT COUNT(*) "
	+ " FROM " + homeworkUser.table + " hu "
	+ " INNER JOIN " + courseUser.table + " cu ON cu.id = hu.course_user_id AND cu.status IN (1,3) AND cu.site_id = " + siteId + " "
	+ " INNER JOIN " + user.table + " u ON u.id = cu.user_id AND u.status != -1 "
	+ " INNER JOIN " + course.table + " c ON c.id = hu.course_id AND c.site_id = " + siteId + " AND c.status != -1 AND c.onoff_type != 'P' "
	+ joinTutor
	+ " INNER JOIN " + homework.table + " h ON h.id = hu.homework_id AND h.site_id = " + siteId + " AND h.status != -1 "
	+ " WHERE hu.status = 1 AND hu.submit_yn = 'Y' "
	+ keywordWhere
	+ dateWhere
	+ statusWhere
);

DataSet list = homeworkUser.query(
	" SELECT hu.course_id, hu.homework_id, hu.course_user_id, hu.reg_date submit_date, hu.confirm_yn "
	+ " , c.course_nm "
	+ " , h.homework_nm "
	+ " , u.user_nm, u.login_id "
	+ " , CASE WHEN IFNULL(c.etc2, '') = 'HAKSA_MAPPED' THEN 'haksa' ELSE 'prism' END source_type "
	+ " FROM " + homeworkUser.table + " hu "
	+ " INNER JOIN " + courseUser.table + " cu ON cu.id = hu.course_user_id AND cu.status IN (1,3) AND cu.site_id = " + siteId + " "
	+ " INNER JOIN " + user.table + " u ON u.id = cu.user_id AND u.status != -1 "
	+ " INNER JOIN " + course.table + " c ON c.id = hu.course_id AND c.site_id = " + siteId + " AND c.status != -1 AND c.onoff_type != 'P' "
	+ joinTutor
	+ " INNER JOIN " + homework.table + " h ON h.id = hu.homework_id AND h.site_id = " + siteId + " AND h.status != -1 "
	+ " WHERE hu.status = 1 AND hu.submit_yn = 'Y' "
	+ keywordWhere
	+ dateWhere
	+ statusWhere
	+ " ORDER BY (CASE WHEN hu.confirm_yn = 'Y' THEN 1 ELSE 0 END) ASC, hu.reg_date DESC "
	+ " LIMIT " + offset + ", " + pageSize + " "
);

while(list.next()) {
	list.put("submitted_at", !"".equals(list.s("submit_date")) ? m.time("yyyy.MM.dd HH:mm", list.s("submit_date")) : "-");
	list.put("confirmed", "Y".equals(list.s("confirm_yn")));
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_total", totalCount);
result.put("rst_page", pageNo);
result.put("rst_limit", pageSize);
result.put("rst_data", list);
result.print();

%>
