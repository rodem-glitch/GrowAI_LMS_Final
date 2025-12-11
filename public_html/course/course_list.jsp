<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseTargetDao courseTarget = new CourseTargetDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CoursePackageDao coursePackage = new CoursePackageDao();
LessonDao lesson = new LessonDao();
LmCategoryDao category = new LmCategoryDao("course");

TutorDao tutor = new TutorDao();
CourseTutorDao courseTutor = new CourseTutorDao();
BookDao book = new BookDao();
CourseBookDao courseBook = new CourseBookDao();

TagModuleDao tagModule = new TagModuleDao();

TagDao tag = new TagDao();

//변수
String today = m.time("yyyyMMdd");
boolean regularBlock = false;
boolean allRegularBlock = true;

String grade = m.rs("grade" ,"");
String term = m.rs("term", "");
String subject = m.rs("subject", "");
String tagType = m.rs("s_tagType", "");

//폼입력
String style = "webzine";
String ord = m.rs("ord");
int categoryId = m.ri("cid", siteId * -1);
int listNum = 10;

////카테고리가 지정될 경우 카테고리 정보 가져옴.
String pTitle = "전체과정";
DataSet cateInfo = category.find("id = " + categoryId);
if(cateInfo.next()) {
	if(categoryId > 0) pTitle = cateInfo.s("category_nm");
	if(!"".equals(cateInfo.s("list_type"))) style = cateInfo.s("list_type");
	if("".equals(ord) && !"".equals(cateInfo.s("sort_type"))) ord = cateInfo.s("sort_type");
	if(cateInfo.i("list_num") > 0) listNum = cateInfo.i("list_num");
}
if(categoryId > 0) {
//	p.setLoop("categories", category.getSubList(siteId, categoryId));
} else if("st asc".equals(ord)) {
	ord = "as asc";
}

if(!"".equals(m.rs("s_style"))) style = m.rs("s_style");
ord = m.getItem(ord.toLowerCase(), course.ordList);

//폼체크
f.addElement("s_style", style, null);
f.addElement("s_type", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("scid", null, null);
f.addElement("ord", null, null);
f.addElement("cid", null, null);
f.addElement("s_tagType", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(listNum);
//lm.setNaviNum(5);
lm.setTable(
	course.table + " a "
	+ " LEFT JOIN " + lesson.table + " l ON a.sample_lesson_id = l.id "
	+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id AND c.module = 'course' AND c.status = 1 "
	+ (!"".equals(tagType) ? " INNER JOIN " + tagModule.table + " tm ON tm.tag_id = " + tagType + " AND tm.module = 'course' AND tm.module_id = a.id " : " ")
);
lm.setFields(
	"a.* "
	+ " , ( CASE "
		+ " WHEN a.course_type = 'A' THEN 'Y' "
		+ " WHEN '" + today + "' BETWEEN a.request_sdate AND a.request_edate THEN 'Y' "
		+ " ELSE 'N' "
	+ " END ) is_request "
	+ " , ( CASE "
		+ " WHEN a.course_type = 'R' AND a.request_sdate > '" + today + "' THEN 'Y' ELSE 'N' "
	+ " END ) is_prev "
	+ " , ( CASE "
		+ " WHEN a.course_type = 'A' THEN 'Y' "
		+ " WHEN '" + today + "' BETWEEN a.study_sdate AND a.study_edate THEN 'Y' "
		+ " ELSE 'N' "
	+ " END ) is_study "
	+ ", (SELECT COUNT(*) FROM " + courseUser.table + " WHERE course_id = a.id AND status NOT IN (-1, -4)) user_cnt "
	+ ", (SELECT COUNT(*) FROM " + courseLesson.table + " WHERE course_id = a.id AND status = 1) lesson_cnt "
	+ ", (SELECT COUNT(*) FROM " + coursePackage.table + " WHERE package_id = a.id) course_cnt "
	+ ", c.category_nm, c.parent_id "
	+ ", l.start_url, l.lesson_type, l.content_width, l.content_height "
);
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("a.status = 1");
lm.addWhere("a.display_yn = 'Y'");
lm.addWhere("a.close_yn = 'N'");
//특정 카테고리가 지정된 경우 하위카테고리 포함 과정 검색
if(categoryId > 0) {
	String subIdx = category.getSubIdx(siteId, m.ri("scid") > 0 ? m.ri("scid") : categoryId);
	lm.addWhere("a.category_id IN (" + (!"".equals(subIdx) ? subIdx : "0") + ")");
}
//학습그룹이 지정된 경우 검색 조건 추가
lm.addWhere(
	"(a.target_yn = 'N'"
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + courseTarget.table + " WHERE course_id = a.id AND group_id IN (" + userGroups + "))"
		: "")
	+ ")"
);
lm.addSearch("a.onoff_type", f.get("s_type"));
lm.addSearch("a.grade", grade);
lm.addSearch("a.term", term);
lm.addSearch("a.subject", subject);

String sField = f.get("s_field", "");
String allowFields = "a.course_nm,a.content1,a.content2";
if(!m.inArray(sField, allowFields)) sField = "";
if(!"".equals(sField)) lm.addSearch(sField, f.get("s_keyword"), "LIKE");
else lm.addSearch(allowFields, f.get("s_keyword"), "LIKE");

//정렬기준에 따라
lm.setOrderBy(!"".equals(ord) ? ord : "a.request_edate DESC, a.reg_date DESC, a.id DESC");

//강사/도서
Vector<String> idx = new Vector<String>();
DataSet list = lm.getDataSet();
while(list.next()) idx.add(list.s("id"));

//강사
Hashtable<String, DataSet> tutorMap = new Hashtable<String, DataSet>();
Hashtable<String, Integer> tutorCountMap = new Hashtable<String, Integer>();
DataSet tutors = new DataSet();
if(idx.size() > 0) {
	tutors = courseTutor.query(
		"SELECT a.course_id, t.* "
		+ " FROM " + courseTutor.table + " a "
		+ " LEFT JOIN " + tutor.table + " t ON a.user_id = t.user_id "
		+ " WHERE a.course_id IN (" + m.join(",", idx.toArray()) + ") "
		+ " ORDER BY a.course_id ASC, t.sort ASC, t.tutor_nm ASC "
	);
	while(tutors.next()) {
		tutors.put("tutor_file_url", m.getUploadUrl(tutors.s("tutor_file")));

		String key = tutors.s("course_id");
		/*
		DataSet temp = tutorMap.containsKey(key) ? tutorMap.get(key) : new DataSet();
		temp.addRow(tutors.getRow());
		tutorMap.put(key, temp);
		*/

		if(!tutorMap.containsKey(key)) {
			DataSet temp = new DataSet();
			temp.addRow(tutors.getRow());
			tutorMap.put(key, temp);
		}

		if(!tutorCountMap.containsKey(key)) {
			tutorCountMap.put(key, 0);
		} else {
			tutorCountMap.put(key, tutorCountMap.get(key) + 1);
		}

	}
}

DataSet tags = tag.find("status != -1", "*", "sort ASC");
if(!tags.next()) { }
/*
//도서
Hashtable<String, DataSet> bookMap = new Hashtable<String, DataSet>();
DataSet books = new DataSet();
if(idx.size() > 0) {
	books = courseBook.query(
		"SELECT a.course_id, b.* "
		+ " FROM " + courseBook.table + " a "
		+ " LEFT JOIN " + book.table + " b ON a.book_id = b.id "
		+ " WHERE a.course_id IN (" + m.join(",", idx.toArray()) + ") "
		+ " ORDER BY a.course_id ASC, a.book_id ASC "
	);
	while(books.next()) {
		String key = books.s("course_id");
		DataSet temp = bookMap.containsKey(key) ? bookMap.get(key) : new DataSet();
		temp.addRow(books.getRow());
		bookMap.put(key, temp);
	}
}
*/
//포맷팅
list.first();
while(list.next()) {

	list.put("request_date", "-");
	if("R".equals(list.s("course_type"))) {
		regularBlock = true;
		list.put("is_regular", true);
		list.put("request_date", m.time(_message.get("format.date.dot"), list.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("request_edate")));
		list.put("study_date", m.time(_message.get("format.date.dot"), list.s("study_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("study_edate")));
		list.put("ready_block", !"".equals(list.s("request_sdate")) ? 0 > m.diffDate("D", list.s("request_sdate"), today) : false);
	} else if("A".equals(list.s("course_type"))) {
		allRegularBlock = false;
		list.put("is_regular", false);
		list.put("request_date", _message.get("list.course.types.A"));
		list.put("study_date", _message.get("list.course.types.A"));
		list.put("ready_block", false);
	}

	//list.put("course_nm_conv", m.cutString(list.s("course_nm"), 48));
	list.put("course_nm_conv", list.s("course_nm"));
	list.put("lesson_time", Malgn.nf(list.d("lesson_time"), 2));
	list.put("lesson_time_conv", m.nf((int)list.d("lesson_time")));
	list.put("lesson_time_hour", (int)Math.floor(list.d("lesson_time")));
	list.put("lesson_time_min", (int)Math.round((list.d("lesson_time") - Math.floor(list.d("lesson_time"))) * 60));

	list.put("subtitle_conv", m.nl2br(list.s("subtitle")));
	list.put("content_conv", m.cutString(m.stripTags(list.s("content1")), 120));
	//list.put("content_conv", !"".equals(list.s("subtitle_conv")) ? list.s("subtitle_conv") : m.cutString(m.stripTags(list.s("content1")), 120));
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

	list.put("price_conv", list.i("price") > 0 ? siteinfo.s("currency_prefix") + m.nf(list.i("price")) + siteinfo.s("currency_suffix") : _message.get("payment.unit.free"));
	list.put("price_conv2", m.nf(list.i("price")));

	list.put("list_price_conv", m.nf(list.i("list_price")));
	list.put("list_price_block", list.i("list_price") > 0);

	int discGroupPrice = list.i("price") - list.i("price") * userGroupDisc / 100; //CouponUserDao.getDiscountPrice() 와 맞춤
	list.put("disc_group_price_block", list.b("disc_group_yn") && 0 < userGroupDisc);
	list.put("disc_group_price", list.b("disc_group_price_block") ? discGroupPrice : list.i("price"));
	list.put("disc_group_price_conv", discGroupPrice > 0 ? siteinfo.s("currency_prefix") + m.nf(list.i("disc_group_price")) + siteinfo.s("currency_suffix") : _message.get("payment.unit.free"));

	list.put("content_width_conv", list.i("content_width") + 20);
	list.put("content_height_conv", list.i("content_height") + 23);

	list.put("is_online", "N".equals(list.s("onoff_type")));
	list.put("is_offline", "F".equals(list.s("onoff_type")));
	list.put("is_blend", "B".equals(list.s("onoff_type")));
	list.put("is_package", "P".equals(list.s("onoff_type")));
	list.put("onoff_type_conv", m.getValue(list.s("onoff_type"), course.onoffPackageTypesMsg));

	list.put("free_block", 0 == list.i("price"));

	String key = list.s("id");
	list.put(".tutors", tutorMap.containsKey(key) ? tutorMap.get(key) : new DataSet());
	list.put("tutor_counts", tutorCountMap.containsKey(key) ? tutorCountMap.get(key).intValue() : 0);
	//list.put(".books", bookMap.containsKey(key) ? bookMap.get(key) : new DataSet());

	//도서
	list.put("book_price", 0);
	DataSet books = courseBook.query(
		"SELECT a.*, b.* "
		+ " FROM " + courseBook.table + " a "
		+ " INNER JOIN " + book.table + " b ON a.book_id = b.id "
		+ " WHERE a.course_id = " + list.i("id") + ""
	);
	while(books.next()) {
		books.put("book_img_url", m.getUploadUrl(books.s("book_img")));
		books.put("book_nm_conv", m.cutString(books.s("book_nm"), 20));
		books.put("book_price_conv", m.nf(books.i("book_price")));
		list.put("book_price", list.i("book_price") + books.i("book_price"));
	}

	//도서 구매 여부
	list.put("book_buy_block", list.i("book_price") > 0 && list.i("price") > 0);
	list.put("book_price_conv", m.nf(list.i("book_price")));
	list.put(".books", books);
	list.put("book_cnt", books.size());

	//수강생여부
	list.put("course_user_id", courseUser.getCourseUserId(list.i("id"), userId, siteId));
	list.put("course_user_block", 0 < list.i("course_user_id"));
}

//출력
p.setLayout(ch);
p.setBody("course.course_list");
p.setVar("p_title", pTitle);
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_type", "list".equals(style));
p.setVar("webzine_type", "webzine".equals(style));
p.setVar("gallery_type", "gallery".equals(style));

p.setVar("category", cateInfo);

p.setVar("grade_title", Malgn.getItem(grade, course.grades));
p.setVar("term_title", Malgn.getItem(term, course.terms));
p.setVar("subject_title", Malgn.getItem(subject, course.subjects));

p.setVar("returl", m.urlencode(request.getRequestURI() + "?" + m.qs()));
p.setVar("style", style);
p.setVar("regular_block", regularBlock);
p.setVar("all_regular_block", allRegularBlock);
p.setLoop("tags", tags);

p.display();

%>