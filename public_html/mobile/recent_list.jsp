<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
int cid = m.ri("cid");
int count = m.ri("cnt") > 0 ? m.ri("cnt") : 100;

String today = m.time("yyyyMMdd");

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
LmCategoryDao category = new LmCategoryDao("course");

//정보-카테고리
DataSet cateInfo = category.find("id = " + cid + "");
if(!cateInfo.next()) return;
String ord = (!"".equals(cateInfo.s("sort_type")) ? cateInfo.s("sort_type") : "re desc");
String subIdx = category.getSubIdx(siteId, m.ri("scid") > 0 ? m.ri("scid") : cid);
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
	+ ", ( SELECT COUNT(*) FROM " + courseUser.table + " WHERE course_id = a.id AND status IN (1,3) ) user_cnt "
	+ " FROM " + course.table + " a "
	+ " INNER JOIN " + category.table + " c ON c.id = a.category_id "
	+ " WHERE a.status = 1 AND a.site_id = " + siteId + " AND a.display_yn = 'Y' AND a.close_yn = 'N' AND a.target_yn = 'N' "
	+ " AND a.category_id IN (" + (!"".equals(subIdx) ? subIdx : "0") + ") "
	+ " ORDER BY " + ord
	, count
);
while(list.next()) {
	list.put("request_date", "-");
	if("R".equals(list.s("course_type"))) {
		list.put("request_date", m.time(_message.get("format.date.dot"), list.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("request_edate")));
		list.put("study_date", m.time(_message.get("format.date.dot"), list.s("study_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("study_edate")));
		list.put("ready_block", 0 > m.diffDate("D", list.s("request_sdate"), today));
	} else if("A".equals(list.s("course_type"))) {
		list.put("request_date", "상시");
		list.put("study_date", "상시");
	}

	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 24));
	list.put("content_conv", m.cutString(m.stripTags(list.s("content1")), 120));
	list.put("course_file_url", m.getUploadUrl(list.s("course_file")));
	list.put("request_block", "Y".equals(list.s("is_request")));

	list.put("price_conv", list.i("price") > 0 ? m.nf(list.i("price")) + "원" : "무료");
}

//출력
p.setLayout(null);
p.setBody("mobile.course_main_list");
p.setLoop("list", list);
p.display();

%>