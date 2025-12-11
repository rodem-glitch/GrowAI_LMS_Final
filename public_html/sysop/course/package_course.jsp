<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int cid = m.ri("cid");
if(cid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");
CoursePackageDao coursePackage = new CoursePackageDao();
CourseProgressDao courseProgress = new CourseProgressDao();
CourseUserDao courseUser = new CourseUserDao();
LessonDao lesson = new LessonDao();

CourseTutorDao courseTutor = new CourseTutorDao();
TutorDao tutor = new TutorDao();
UserDao user = new UserDao();
MCal mcal = new MCal();

//카테고리
DataSet categories = category.getList(siteId);

//정보-과정
DataSet info = course.find(
	"id = " + cid + " AND onoff_type = 'P' AND status != -1 AND site_id = " + siteId + ""
	+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("cate_name", category.getTreeNames(info.i("category_id")));
info.put("status_conv", m.getItem(info.s("status"), course.statusList));
if("R".equals(info.s("course_type"))) {
	info.put("request_date", m.time("yyyy.MM.dd", info.s("request_sdate")) + " - " + m.time("yyyy.MM.dd", info.s("request_edate")));
	info.put("study_date", m.time("yyyy.MM.dd", info.s("study_sdate")) + " - " + m.time("yyyy.MM.dd", info.s("study_edate")));
	info.put("study_sdate_conv", m.time("yyyy-MM-dd", info.s("study_sdate")));
	info.put("study_edate_conv", m.time("yyyy-MM-dd", info.s("study_edate")));
	info.put("alltime_block", false);
} else if("A".equals(info.s("course_type"))) {
	info.put("request_date", "상시");
	info.put("study_date", "상시");
	info.put("alltime_block", true);
}
info.put("course_type_conv", m.getItem(info.s("course_type"), course.types));
info.put("online_block", "N".equals(info.s("onoff_type")));
info.put("display_conv", info.b("display_yn") ? "정상" : "숨김");

int progressCnt = courseProgress.getOneInt(
	" SELECT COUNT(c.course_id) FROM " + courseProgress.table + " a "
	+ " LEFT JOIN " + courseUser.table + " c ON	c.id = a.course_user_id "
	+ " WHERE c.course_id = " + cid + " AND a.status != -1 "
);

if("add".equals(m.rs("mode"))) {
	//추가
	if(0 == coursePackage.findCount("package_id = " + cid + " AND course_id = " + m.ri("cid"))) {
		coursePackage.item("package_id", cid);
		coursePackage.item("course_id", m.ri("cid"));
		coursePackage.item("site_id", siteId);
		coursePackage.item("sort", coursePackage.getLastSort(cid));
		coursePackage.insert();
	}

	//이동
	m.redirect("package_course.jsp?cid=" + cid);
	return;
} else if("del".equals(m.rs("mode"))) {
	//삭제
	if("".equals(f.get("idx"))) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	if(-1 == coursePackage.execute(
			"DELETE FROM " + coursePackage.table + " "
			+ " WHERE package_id = " + cid + " AND course_id IN (" + f.get("idx") + ")")
	) {
		m.jsError("과정을 삭제하는 중 오류가 발생했습니다.");
		return;
	};

	coursePackage.autoSort(cid);

	//제한
	if(info.b("display_yn") && 0 >= coursePackage.findCount("package_id = " + cid)) {
		course.item("sale_yn", "N");
		course.update("id = " + cid + " AND onoff_type = 'P' AND site_id = " + siteId + " AND status != -1");
		m.jsAlert("해당 패키지에 등록된 과정이 없어\\n패키지가 판매 중지 상태로 변경되었습니다.");
	}

	//이동
	m.jsReplace("package_course.jsp?" + m.qs("mode, idx"));
	return;
}

//수정
if(m.isPost() && f.validate()) {
	if(f.getArr("course_id") != null) {
		int sort = 0;
		for(int i = 0; i < f.getArr("course_id").length; i++) {
			coursePackage.item("sort", ++sort);
			if(!coursePackage.update("package_id = " + cid + " AND course_id = " + f.getArr("course_id")[i])) { }
		}
	}

	m.jsAlert("수정되었습니다.");
	m.jsReplace("package_course.jsp?" + m.qs(), "parent");
	return;
}

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(1000);
lm.setTable(
	coursePackage.table + " a "
	+ " INNER JOIN " + course.table + " c ON "
		+ " a.course_id = c.id "
);
lm.setFields("c.*, a.*");
lm.addWhere("a.package_id = " + cid + "");
lm.setOrderBy("a.sort ASC");

//포맷팅
DataSet sortList = new DataSet();
DataSet list = lm.getDataSet();
while(list.next()) {

	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 40));
	list.put("status_conv", m.getItem(list.s("status"), course.statusList));
	list.put("display_conv", list.b("display_yn") ? "정상" : "숨김");

	list.put("price_conv", m.nf(list.i("price")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("course_file_url", !"".equals(list.s("course_file")) ? siteDomain + m.getUploadUrl(list.s("course_file")) : "");
	list.put("cate_name", category.getTreeNames(list.i("category_id")));
	list.put("type_conv", m.getItem(list.s("course_type"), course.types));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffTypes));

	list.put("alltimes_block", "A".equals(list.s("course_type")));
	list.put("request_sdate_conv", m.time("yyyy.MM.dd", list.s("request_sdate")));
	list.put("request_edate_conv", m.time("yyyy.MM.dd", list.s("request_edate")));
	list.put("study_sdate_conv", m.time("yyyy.MM.dd", list.s("study_sdate")));
	list.put("study_edate_conv", m.time("yyyy.MM.dd", list.s("study_edate")));

	list.put("curr_sort", list.i("sort") * 1000);

	sortList.addRow();
	sortList.put("id", list.i("__asc"));
	sortList.put("name", list.i("__asc"));
}

//출력
p.setBody("course.package_course");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("cid,id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar(info);

p.setLoop("sort_list", sortList);
p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes(10));

p.setVar("tab_course", "current");
p.display();

%>