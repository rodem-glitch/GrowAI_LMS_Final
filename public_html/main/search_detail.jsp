<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String subject = m.rs("subject");
String keyword = m.replace(m.rs("s_keyword").trim().replaceAll("[^가-힣a-zA-Z0-9\\s]", ""), " ", "|");
while(-1 < keyword.indexOf("||")) keyword = m.replace(keyword, "||", "|");
if(keyword.startsWith("|")) keyword = keyword.substring(1);
if(keyword.endsWith("|")) keyword = keyword.substring(0, keyword.length() - 1);
if("".equals(subject) || "".equals(keyword)) { m.jsError(_message.get("alert.common.enter_keyword")); return; }
if(100 < keyword.length()) keyword = m.cutString(keyword, 100, "");

//객체
CourseDao course = new CourseDao();
PostDao post = new PostDao();
ClPostDao clPost = new ClPostDao();
BoardDao board = new BoardDao();
TutorDao tutor = new TutorDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseTargetDao courseTarget = new CourseTargetDao();
WebtvDao webtv = new WebtvDao();
WebtvTargetDao webtvTarget = new WebtvTargetDao();
LmCategoryDao category = new LmCategoryDao();
LmCategoryTargetDao categoryTarget = new LmCategoryTargetDao();
SearchLogDao searchLog = new SearchLogDao(request);

//로그
if(!searchLog.addLog(siteId, userId, m.rs("s_keyword"))) { }


//폼체크
Form f2 = new Form("form_search");
f2.setRequest(request);
f2.addElement("s_keyword", null, null);

//변수
String today = m.time("yyyyMMdd");
String searchType = "post".equals(subject) ? "post" : ("webtv".equals(subject) ? "webtv" : "course");
String[] subjectList = {"tutor=>강사", "course=>강의", "webtv=>방송", "post=>게시물"};
ListManager lm = new ListManager();
DataSet list = new DataSet();

if("post".equals(searchType)) {
	//목록
	//lm.d(out);
	lm.setRequest(request);
	lm.setListNum(10);
	lm.setTable(
		post.table + " a "
		+ " INNER JOIN " + board.table + " b ON b.id = a.board_id AND b.site_id = " + siteId + " AND b.status = 1 "
			+ (userId > 0 ? " AND b.auth_list LIKE '%|U|%' " : " AND b.auth_list LIKE '%|0|%' ")
	);
	lm.setFields("a.*, b.board_nm, b.code, b.layout, b.comment_yn");
	lm.addWhere("(a.subject REGEXP ? OR a.content REGEXP ?)", new Object[] {keyword, keyword});
	lm.addWhere("a.site_id = " + siteId);
	lm.addWhere("a.secret_yn = 'N'");
	lm.addWhere("a.display_yn = 'Y'");
	lm.addWhere("a.status = 1");
	lm.addWhere("a.depth = 'A'");
	lm.setOrderBy("a.id desc");

	//포맷팅
	list = lm.getDataSet();
	while(list.next()) {
		list.put("subject_conv", m.cutString(list.s("subject"), 80));
		list.put("reg_date_conv", m.time(_message.get("format.date.dot"), list.s("reg_date")));
		list.put("hit_cnt_conv", m.nf(list.i("hit_cnt")));
		list.put("comment_conv", list.b("comment_yn") && list.i("comm_cnt") > 0 ? "(" + list.i("comm_cnt") + ")" : "");
	}
} else if("webtv".equals(searchType)) {
	//목록
	//lm.d(out);
	lm.setRequest(request);
	lm.setListNum(10);
	lm.setTable(
		webtv.table + " a "
		+ " INNER JOIN " + category.table + " c ON a.category_id = c.id AND c.status = 1 "
	);
	lm.setFields("a.*, c.category_nm, IF('" + today + "' >= a.open_date, 'Y', 'N') is_open");
	lm.addWhere("(a.webtv_nm REGEXP ? OR a.subtitle REGEXP ? OR a.content REGEXP ? OR a.keywords REGEXP ?)", new Object[] {keyword, keyword, keyword, keyword}); 
	lm.addWhere("a.site_id = " + siteId + "");
	lm.addWhere("a.display_yn = 'Y'");
	lm.addWhere("a.status = 1");
	lm.addWhere("a.open_date <= '" + m.time("yyyyMMddHHmmss") + "'");
	lm.addWhere( //시청대상그룹
		"(a.target_yn = 'N'"
		+ (!"".equals(userGroups)
			? " OR EXISTS (SELECT 1 FROM " + webtvTarget.table + " WHERE webtv_id = a.id AND group_id IN (" + userGroups + "))"
			: "")
		+ ")"
	);
	lm.addWhere( //카테고리시청대상그룹
		"(c.target_yn = 'N'" //카테고리시청대상그룹
		+ (!"".equals(userGroups)
			? " OR EXISTS (SELECT 1 FROM " + categoryTarget.table + " WHERE category_id = c.id AND group_id IN (" + userGroups + "))"
			: "")
		+ ")"
	);
	lm.setOrderBy("a.open_date desc, a.id desc");

	//포맷팅
	list = lm.getDataSet();
	while(list.next()) {
		list.put("webtv_nm_conv", m.cutString(list.s("webtv_nm"), 70));
		
		list.put("subtitle_conv", m.nl2br(list.s("subtitle")));
		list.put("length_conv", m.strrpad(list.s("length_min"), 2, "0") + ":" + m.strrpad(list.s("length_sec"), 2, "0"));

		if(!"".equals(list.s("webtv_file"))) {
			list.put("webtv_file_url", m.getUploadUrl(list.s("webtv_file")));
		} else if("".equals(list.s("webtv_file_url"))) {
			list.put("webtv_file_url", "/common/images/default/noimage_webtv.jpg");
		}

		list.put("content_width_conv", list.i("content_width") + 20);
		list.put("content_height_conv", list.i("content_height") + 23);
		
		list.put("hit_cnt_conv", m.nf(list.i("hit_cnt")));
		list.put("reg_date_conv", m.time(_message.get("format.datetime.dot"), list.s("reg_date")));
		list.put("open_date_conv", m.time(_message.get("format.datetime.dot"), list.s("open_date")));

	}
} else {
	//목록
	//lm.d(out);
	lm.setRequest(request);
	lm.setListNum(10);
	lm.setTable(
		course.table + " a "
		+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id "
		+ ("tutor".equals(subject) ?
			" INNER JOIN " + courseTutor.table + " ct ON ct.course_id = a.id "
			+ " INNER JOIN " + tutor.table + " t ON t.user_id = ct.user_id AND t.status = 1 "
		: "")
	);
	lm.setFields("a.*, c.category_nm");
	if("course".equals(subject)) lm.addWhere("a.course_nm REGEXP ?", new Object[] {keyword}); 
	else if("tutor".equals(subject)) lm.addWhere("t.tutor_nm REGEXP ?", new Object[] {keyword});
	lm.addWhere("a.site_id = " + siteId + "");
	lm.addWhere("a.status = 1");
	lm.addWhere("a.display_yn = 'Y'");
	lm.addWhere("a.close_yn = 'N'");
	lm.addWhere(
		"(a.target_yn = 'N'"
		+ (!"".equals(userGroups)
			? " OR EXISTS (SELECT 1 FROM " + courseTarget.table + " WHERE course_id = a.id AND group_id IN (" + userGroups + "))"
			: "")
		+ ")"
	);
	lm.setOrderBy("a.id desc");

	//포맷팅
	list = lm.getDataSet();
	while(list.next()) {
		list.put("request_date", "-");
		if("R".equals(list.s("course_type"))) {
			list.put("is_regular", true);
			list.put("request_date", m.time(_message.get("format.date.dot"), list.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("request_edate")));
			list.put("study_date", m.time(_message.get("format.date.dot"), list.s("study_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("study_edate")));
			list.put("ready_block", 0 > m.diffDate("D", list.s("request_sdate"), today));
		} else if("A".equals(list.s("course_type"))) {
			list.put("is_regular", false);
			list.put("request_date", "상시");
			list.put("study_date", "상시");
			list.put("ready_block", false);
		}

		list.put("course_nm_conv", m.cutString(list.s("course_nm"), 48));
		
		list.put("subtitle_conv", m.nl2br(list.s("subtitle")));
		list.put("content_conv", m.cutString(m.stripTags(list.s("subtitle")), 120));
		//list.put("content_conv", !"".equals(list.s("subtitle_conv")) ? list.s("subtitle_conv") : m.cutString(m.stripTags(list.s("content1")), 120));

		if(!"".equals(list.s("course_file"))) {
			list.put("course_file_url", m.getUploadUrl(list.s("course_file")));
		} else {
			list.put("course_file_url", "/html/images/common/noimage_course.gif");
		}
		
		list.put("is_online", "N".equals(list.s("onoff_type")));
		list.put("is_offline", "F".equals(list.s("onoff_type")));
		list.put("is_blend", "B".equals(list.s("onoff_type")));
		list.put("is_package", "P".equals(list.s("onoff_type")));
		list.put("onoff_type_conv", m.getValue(list.s("onoff_type"), course.onoffPackageTypesMsg));

		list.put("tutor_nm", courseTutor.getTutorSummary(list.i("id")));
	}
}

//출력
p.setLayout("search");
p.setBody("main.search_detail");
p.setVar("p_title", m.getItem(subject, subjectList));
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("subject_query", m.qs("id,subject,page"));
p.setVar("form_script", f2.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("search_total", lm.getTotalNum());

//p.setVar("s_keyword", keyword.replaceAll("\\|", " "));
p.setVar(searchType + "_block", true);
p.display();

%>