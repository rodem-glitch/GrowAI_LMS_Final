<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(132, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

//폼입력
int uid = m.ri("uid");
String ek = m.rs("ek");
String key = m.rs("k");

//변수
String today = m.time("yyyyMMdd");

//제한
if(!ek.equals(m.encrypt(uid + "_LMS-USCH2017!_" + key + "_" + today))) { m.jsError("잘못된 접근입니다."); return; }

//정보-회원
DataSet uinfo = user.find("id = ? AND site_id = ? AND status != -1", new Object[] { uid, siteId });
if(!uinfo.next()) { m.jsError("잘못된 접근입니다."); return; }
uinfo.put("gender_conv", m.getItem(uinfo.s("gender"), user.genders));
uinfo.put("birthday_conv", m.time("yyyy.MM.dd", uinfo.s("birthday")));
user.maskInfo(uinfo);

//기록-개인정보조회
if(uinfo.size() > 0 && !isBlindUser) _log.add("V", Menu.menuNm, uinfo.size(), "이러닝 운영", uinfo);

//수강중인 과정
DataSet list1 = courseUser.query(
	"SELECT a.*, c.course_nm, c.course_type, c.year, c.step "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id AND u.status != -1 "
	+ " WHERE a.user_id = " + uid + " AND a.status IN (0, 1, 3) "
	+ " AND a.close_yn = 'N' AND a.end_date >= '" + today + "' "
	+ " ORDER BY a.start_date ASC, a.id DESC "
);
while(list1.next()) {
	list1.put("start_date_conv", m.time("yyyy.MM.dd", list1.s("start_date")));
	list1.put("end_date_conv", m.time("yyyy.MM.dd", list1.s("end_date")));
	list1.put("study_date_conv", list1.s("start_date_conv") + " - " + list1.s("end_date_conv"));
	list1.put("course_nm_conv", m.cutString(list1.s("course_nm"), 50));
	list1.put("progress_ratio", m.nf(list1.d("progress_ratio"), 1));
	list1.put("total_score", m.nf(list1.d("total_score"), 1));
	list1.put("type_conv", m.getItem(list1.s("course_type"), course.types));

	String status = "";
	if(list1.i("status") == 0) status = "승인대기";
	else if(0 > m.diffDate("D", list1.s("start_date"), today)) status = "학습대기";
	else {
		if(list1.b("complete_yn")) status = "수료";
		else status = "학습중";
	}

	list1.put("status_conv", status);
}

//종료된 과정
DataSet list2 = courseUser.query(
	"SELECT a.*, c.course_nm, c.course_type, c.restudy_yn, c.restudy_day, c.year, c.step "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id AND u.status != -1 "
	+ " WHERE a.user_id = " + uid + " AND a.status IN (1, 3) "
	+ " AND (a.end_date < '" + today + "' OR a.close_yn = 'Y') "
	+ " ORDER BY a.end_date DESC, a.id DESC "
);
while(list2.next()) {
	list2.put("start_date_conv", m.time("yyyy.MM.dd", list2.s("start_date")));
	list2.put("end_date_conv", m.time("yyyy.MM.dd", list2.s("end_date")));
	list2.put("study_date_conv", list2.s("start_date_conv") + " - " + list2.s("end_date_conv"));
	list2.put("course_nm_conv", m.cutString(list2.s("course_nm"), 50));
	list2.put("progress_ratio", m.nf(list2.d("progress_ratio"), 1));
	list2.put("total_score", m.nf(list2.d("total_score"), 1));
	list2.put("type_conv", m.getItem(list2.s("course_type"), course.types));
	list2.put("status_conv", list2.b("complete_yn") ? "수료" : "미수료");

	list2.put("restudy_block", false);
	if(list2.b("restudy_yn")) {
		String edate = m.addDate("D", list2.i("restudy_day"), list2.s("end_date"), "yyyyMMdd");
		list2.put("restudy_block", list2.b("restudy_yn") && 0 <= m.diffDate("D", today, edate));
	}
}

//출력
p.setBody("complete.user_course");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,sid"));
p.setVar("form_script", f.getScript());

p.setVar("uinfo", uinfo);
p.setLoop("list1", list1);
p.setLoop("list2", list2);

p.display();

%>