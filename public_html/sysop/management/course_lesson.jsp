<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }


//객체
UserDao user = new UserDao();
LessonDao lesson = new LessonDao();
LmCategoryDao category = new LmCategoryDao("course");
CourseUserDao courseUser = new CourseUserDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseSectionDao courseSection = new CourseSectionDao();
CourseProgressDao courseProgress = new CourseProgressDao();

//목록-수강생
DataSet users = courseUser.query(
	" SELECT a.id, u.user_nm, u.login_id "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.status != -1 "
	+ " WHERE a.course_id = " + courseId + " AND a.status IN (1,3) "
	+ " ORDER BY a.id ASC "
);
int total = users.size();
String idx = "0";
while(users.next()) idx += "," + users.s("id");

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
//lm.setListMode(0);
lm.setListNum(1000);
lm.setTable(
	courseLesson.table + " a "
	+ " INNER JOIN " + lesson.table + " b ON a.lesson_id = b.id "
	+ " LEFT JOIN " + courseSection.table + " cs ON a.section_id = cs.id AND cs.status = 1 "
	+ " LEFT JOIN ("
	+ "		SELECT lesson_id, count(*) complete_cnt FROM " + courseProgress.table
	+ "		WHERE course_user_id IN (" + idx + ") AND complete_yn = 'Y'"
	+ "		GROUP BY lesson_id"
	+ " ) p ON p.lesson_id = a.lesson_id"
);
lm.setFields(
	"a.*, p.complete_cnt"
	+ ", b.onoff_type, b.lesson_nm, b.lesson_type, b.content_width, b.content_height, b.start_url, b.mobile_a, b.mobile_i "
	+ ", cs.id section_id, cs.section_nm "
);
lm.addWhere("a.status != -1");
lm.addWhere("a.course_id = " + courseId + "");
lm.setOrderBy("a.chapter ASC");

//포맷팅
DataSet sortList = new DataSet();
DataSet list = lm.getDataSet();
int no = 1;
int lastSectionId = 0;
while(list.next()) {
	list.put("no", no++);
	list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), "W".equals(siteinfo.s("ovp_vendor")) ? lesson.types : lesson.catenoidTypes));
	list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm"), 30));
	list.put("complete_percent", (int)m.getPercent(list.i("complete_cnt"), total));
	list.put("complete_cnt_conv", m.nf(list.i("complete_cnt")));

	list.put("start_date_conv", m.time("yyyy-MM-dd", list.s("start_date")));
	list.put("end_date_conv", m.time("yyyy-MM-dd", list.s("end_date")));

	list.put("online_block", "N".equals(list.s("onoff_type")) || "T".equals(list.s("onoff_type")));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), lesson.onoffTypes));
	
	if(lastSectionId != list.i("section_id") && 0 < list.i("section_id")) {
		lastSectionId = list.i("section_id");
		list.put("section_block", true);
	} else {
		list.put("section_block", false);
	}
}

cinfo.put("online_block", "N".equals(cinfo.s("onoff_type")));
cinfo.put("onoff_type_conv", m.getItem(cinfo.s("onoff_type"), lesson.onoffTypes));

//엑셀
if("excel".equals(m.rs("mode"))) {
	//변수
	Hashtable<String, String> cpmap = new Hashtable<String, String>();
	ArrayList<String> columns = new ArrayList<String>();
	columns.add("__ord=>No");
	columns.add("id=>회원ID");
	columns.add("user_nm=>회원명");
	columns.add("login_id=>로그인아이디");

	//목록-수강생-courseProgress 인덱스 검색용
	DataSet rs = courseUser.find("course_id = " + courseId + " AND status = 1", "id");
	if(1 > rs.size()) { m.jsAlert("해당 수강생 정보가 없습니다."); return; }
	StringBuffer sb = new StringBuffer();
	while(rs.next()) { sb.append(","); sb.append(rs.s("id")); }
	String userIdx = " AND course_user_id IN (" + sb.toString().substring(1) + ")";

	//목록-진도
	DataSet cplist = courseProgress.find("status = 1" + userIdx);
	while(cplist.next()) {
		cpmap.put(cplist.i("course_user_id") + "_" + cplist.i("lesson_id"), cplist.s("ratio"));
	}
	
	//포맷팅-회원차시
	list.first();
	while(list.next()) {
		int lid = list.i("lesson_id");
		users.first();
		while(users.next()) {
			int uid = users.i("id");
			String key = uid + "_" + lid;
			users.put("complete_" + list.i("lesson_id"), cpmap.containsKey(key) ? cpmap.get(key) : "-");
		}

		columns.add("complete_" + lid + "=>[" + list.s("no") + "차시] " + list.s("lesson_nm"));
	}

	//엑셀출력
	ExcelWriter ex = new ExcelWriter(response, cinfo.s("course_nm") + "_전체진도현황(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(users, columns.toArray(new String[] {}), cinfo.s("course_nm") + "_전체진도현황(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("management.course_lesson");
p.setVar("p_title", ptitle);
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("cid,id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());

p.setVar("course", cinfo);
if("N".equals(cinfo.s("onoff_type"))) {
	p.setVar("attend_cnt", "완료자수");
	p.setVar("attend_ratio", "완료율");
	p.setVar("attend_manage", "진도관리");
} else {
	p.setVar("attend_cnt", "출석수");
	p.setVar("attend_ratio", "출석율");
	p.setVar("attend_manage", "출결관리");
}

p.display();

%>