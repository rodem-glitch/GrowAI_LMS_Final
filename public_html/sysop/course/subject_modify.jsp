<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(79, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
SubjectDao subject = new SubjectDao();
CourseDao course = new CourseDao();

//정보
DataSet info = subject.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//폼체크
f.addElement("course_nm", info.s("course_nm"), "hname:'과정명', required:'Y'");
f.addElement("status", info.s("status"), "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	subject.item("course_nm", f.get("course_nm"));
	subject.item("status", f.get("status"));
	if(!subject.update("id = " + id + "")) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsReplace("subject_list.jsp?" + m.qs("id"), "parent");
	return;
}

//포멧팅
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("course_cnt_conv", course.findCount("status != -1 AND subject_id = " + id + ""));

//목록
DataSet courses = course.find("status != -1 AND subject_id = " + id + "", "*", "year ASC, step ASC");
while(courses.next()) {
	courses.put("status_conv", m.getItem(courses.s("status"), course.statusList));
	courses.put("alltimes_block", "A".equals(courses.s("course_type")));
	courses.put("study_sdate_conv", m.time("yyyy.MM.dd", courses.s("study_sdate")));
	courses.put("study_edate_conv", m.time("yyyy.MM.dd", courses.s("study_edate")));
}

//출력
p.setBody("course.subject_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);
p.setLoop("courses", courses);

p.setLoop("status_list", m.arr2loop(subject.statusList));
p.display();

%>