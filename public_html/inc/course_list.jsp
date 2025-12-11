<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
String ord = m.replace(m.rs("ord"), "_", " ");
int categoryId = m.ri("cid", siteId * -1);
int count = m.ri("cnt") > 0 ? m.ri("cnt") : 100;
int strlen = m.ri("strlen") > 0 ? m.ri("strlen") : 24;
int line = m.ri("line") > 0 ? m.ri("line") : 100;

//변수
String today = m.time("yyyyMMdd");
String subIdx = "";

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseTargetDao courseTarget = new CourseTargetDao();
LmCategoryDao category = new LmCategoryDao("course");

//정보-카테고리
DataSet cateInfo = category.find("id = " + categoryId + "");
if(cateInfo.next()) {
	if("".equals(ord)) ord = !"".equals(cateInfo.s("sort_type")) ? cateInfo.s("sort_type") : "re desc";
}
if(categoryId > 0) {
	subIdx = category.getSubIdx(siteId, m.ri("scid") > 0 ? m.ri("scid") : categoryId);
} else if("st asc".equals(ord)) {
	ord = "as asc";
}
ord = m.getItem(ord.toLowerCase(), course.ordList);

//목록
//course.d(out);
DataSet list = course.query(
	"SELECT a.*"
	+ " , ( CASE "
		+ " WHEN a.course_type = 'A' THEN 'Y' "
		+ " WHEN '" + today + "' BETWEEN a.request_sdate AND a.request_edate THEN 'Y' "
		+ " ELSE 'N' "
	+ " END ) is_request "
	//+ ", ( SELECT COUNT(*) FROM " + courseUser.table + " WHERE course_id = a.id AND status IN (1,3) ) user_cnt "
	+ ", ( SELECT COUNT(*) FROM " + courseLesson.table + " WHERE course_id = a.id AND status = 1) lesson_cnt "
	+ " FROM " + course.table + " a "
	+ " WHERE a.status = 1 AND a.site_id = " + siteId + " AND a.display_yn = 'Y' AND a.close_yn = 'N' "
	//조건-카테고리
	+ (categoryId > 0 ? " AND a.category_id IN (" + (!"".equals(subIdx) ? subIdx : "0") + ") " : "")
	//조건-학습그룹
	+ " AND (a.target_yn = 'N'"
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + courseTarget.table + " WHERE course_id = a.id AND group_id IN (" + userGroups + "))"
		: "")
	+ ")"
	+ " ORDER BY " + ord
	, count
);
while(list.next()) {
	list.put("request_date", "-");
	if("R".equals(list.s("course_type"))) {
		list.put("request_date", m.time(_message.get("format.date.dot"), list.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("request_edate")));
		list.put("study_date", m.time(_message.get("format.date.dot"), list.s("study_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("study_edate")));
		list.put("ready_block", !"".equals(list.s("request_sdate")) ? 0 > m.diffDate("D", list.s("request_sdate"), today) : false);
	} else if("A".equals(list.s("course_type"))) {
		list.put("request_date", "상시");
		list.put("study_date", m.nf(list.i("lesson_day")) + "일");
	}

	list.put("course_nm_conv", m.cutString(list.s("course_nm"), strlen));
	list.put("subtitle_conv", m.nl2br(list.s("subtitle")));
	list.put("content_conv", m.cutString(m.stripTags(list.s("content1")), 120));
	if(!"".equals(list.s("course_file"))) {
		list.put("course_file_url", m.getUploadUrl(list.s("course_file")));
	} else {
		list.put("course_file_url", "/html/images/common/noimage_course.gif");
	}
	list.put("request_block", "Y".equals(list.s("is_request")));
	list.put("price_conv", list.i("price") > 0 ? m.nf(list.i("price")) + "원" : "무료");
	list.put("list_price_conv", m.nf(list.i("list_price")));
	list.put("list_price_block", list.i("list_price") > 0);

	list.put("class", list.i("__ord") % line == 1 ? "first" : "");
	list.put("tutor_nm", courseTutor.getTutorSummary(list.i("id")));
}

//출력
p.setLayout(null);
p.setBody("inc.course_list");
p.setLoop("list", list);

p.display();

%>