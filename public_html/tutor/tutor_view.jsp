<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(0 == id) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
TutorDao tutor = new TutorDao();
UserDao user = new UserDao();
CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseTargetDao courseTarget = new CourseTargetDao();

//정보
DataSet info = user.query(
	" SELECT t.* "
	+ " FROM " + user.table + " a "
	+ " INNER JOIN " + tutor.table + " t ON a.id = t.user_id AND t.status = 1 "
	+ " WHERE a.site_id = " + siteId + " AND a.tutor_yn = 'Y' AND a.display_yn = 'Y' AND a.status = 1 AND a.id = ? "
	, new Object[] { id }
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

if(!"".equals(info.s("tutor_file"))) {
	info.put("tutor_file_url", m.getUploadUrl(info.s("tutor_file")));
} else {
	info.put("tutor_file_url", "/html/images/common/noimage_tutor.jpg");
}

//변수
String today = m.time("yyyyMMdd");
boolean regularBlock = false;
boolean allRegularBlock = true;

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setTable(
	courseTutor.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " AND c.status = 1 AND display_yn = 'Y' "
);
lm.setFields(
	"c.*"
	+ " , ( CASE "
		+ " WHEN c.course_type = 'A' THEN 'Y' "
		+ " WHEN '" + today + "' BETWEEN c.request_sdate AND c.request_edate THEN 'Y' "
		+ " ELSE 'N' "
	+ " END ) is_request "
);
lm.addWhere("a.user_id = ?", new Object[] { id });
lm.addWhere("a.type = 'major'");

//학습그룹이 지정된 경우 검색 조건 추가
lm.addWhere(
	"(c.target_yn = 'N'"
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + courseTarget.table + " WHERE course_id = c.id AND group_id IN (" + userGroups + "))"
		: "")
	+ ")"
);

//정렬기준에 따라
lm.setOrderBy("c.category_id DESC, c.sort ASC");
DataSet list = lm.getDataSet();

//포맷팅
list.first();
while(list.next()) {

	list.put("request_date", "-");
	if("R".equals(list.s("course_type"))) {
		regularBlock = true;
		list.put("is_regular", true);
		list.put("request_date", m.time(_message.get("format.date.dot"), list.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("request_edate")));
		list.put("study_date", m.time(_message.get("format.date.dot"), list.s("study_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("study_edate")));
		list.put("ready_block", 0 > m.diffDate("D", list.s("request_sdate"), today));
	} else if("A".equals(list.s("course_type"))) {
		allRegularBlock = false;
		list.put("is_regular", false);
		list.put("request_date", "상시");
		list.put("study_date", "상시");
		list.put("ready_block", false);
	}

	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 48));
	list.put("subtitle_conv", m.nl2br(list.s("subtitle")));	
	list.put("content_conv", m.cutString(m.stripTags(list.s("content1")), 120));
	list.put("content_html", m.cutString(list.s("content1"), 200));
	list.put("content_nl2br", m.cutString(m.nl2br(list.s("content1")), 120));

	list.put("content2_conv", m.cutString(m.stripTags(list.s("content2")), 120));
	list.put("content2_html", m.cutString(list.s("content2"), 200));
	list.put("content2_nl2br", m.cutString(m.nl2br(list.s("content2")), 120));
	if(!"".equals(list.s("course_file"))) {
		list.put("course_file_url", m.getUploadUrl(list.s("course_file")));
	} else {
		list.put("course_file_url", "/html/images/common/noimage_course.gif");
	}

	list.put("request_block",
		(
			("Y".equals(list.s("is_request")) && "N".equals(list.s("limit_people_yn")))
			|| ("Y".equals(list.s("is_request")) && "Y".equals(list.s("limit_people_yn")) && list.i("limit_people") > list.i("user_cnt"))
		) && !list.b("close_yn") && list.b("sale_yn")
	);

	list.put("price_conv", list.i("price") > 0 ? m.nf(list.i("price")) + "원" : "무료");
	list.put("price_conv2", m.nf(list.i("price")));

	list.put("list_price_conv", m.nf(list.i("list_price")));
	list.put("list_price_block", list.i("list_price") > 0);

	list.put("content_width_conv", list.i("content_width") + 20);
	list.put("content_height_conv", list.i("content_height") + 23);
	
	list.put("is_online", "N".equals(list.s("onoff_type")));
	list.put("is_offline", "F".equals(list.s("onoff_type")));
	list.put("is_blend", "B".equals(list.s("onoff_type")));
	list.put("is_package", "P".equals(list.s("onoff_type")));
	list.put("onoff_type_conv", m.getValue(list.s("onoff_type"), course.onoffPackageTypesMsg));

	list.put("free_block", 0 == list.i("price"));
}

//m.p(list);

//출력
p.setLayout(ch);
p.setBody("tutor.tutor_view");
p.setVar("p_title", "강사소개");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());

p.setVar(info);
//p.setLoop("clist", clist);

p.display();

%>