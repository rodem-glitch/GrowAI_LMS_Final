<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- `project` 화면의 "과정탐색/과정선택"에서 교수자가 만든 과정(프로그램) 목록을 바로 보여주기 위함입니다.

SubjectDao subject = new SubjectDao();
CourseDao course = new CourseDao();

String keyword = m.rs("s_keyword");
int tutorId = m.ri("tutor_id"); //관리자용 필터(선택)

ArrayList<Object> params = new ArrayList<Object>();
String whereKeyword = "";
if(!"".equals(keyword)) {
	whereKeyword = " AND a.course_nm LIKE ? ";
	params.add("%" + keyword + "%");
}

//왜: 교수자는 본인 과정만, 관리자는 전체(또는 특정 교수자) 과정을 조회할 수 있어야 합니다.
String whereOwner = "";
if(!isAdmin) {
	whereOwner = " AND a.user_id = " + userId + " ";
} else if(0 < tutorId) {
	whereOwner = " AND a.user_id = " + tutorId + " ";
}

DataSet list = subject.query(
	" SELECT a.id, a.user_id, a.course_nm, a.start_date, a.end_date, a.reg_date, a.status "
	+ " , (SELECT COUNT(*) FROM " + course.table + " c "
		+ " WHERE c.site_id = " + siteId + " AND c.subject_id = a.id AND c.status != -1) course_cnt "
	+ " FROM " + subject.table + " a "
	+ " WHERE a.site_id = " + siteId + " AND a.status != -1 "
	+ whereOwner
	+ whereKeyword
	+ " ORDER BY a.id DESC "
	, params.toArray()
);

while(list.next()) {
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 100));
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));

	String sdate = list.s("start_date");
	String edate = list.s("end_date");
	list.put("start_date_conv", !"".equals(sdate) ? m.time("yyyy.MM.dd", sdate) : "");
	list.put("end_date_conv", !"".equals(edate) ? m.time("yyyy.MM.dd", edate) : "");
	list.put("training_period", (!"".equals(sdate) && !"".equals(edate)) ? (m.time("yyyy.MM.dd", sdate) + " - " + m.time("yyyy.MM.dd", edate)) : "");

	list.put("course_cnt_conv", m.nf(list.i("course_cnt")));
	list.put("status_conv", m.getItem(list.s("status"), subject.statusList));
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>
