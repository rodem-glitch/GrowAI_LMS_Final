<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.reqInt("cuid");
if(id == 0) { m.jsErrClose("기본키는 반드시 존재해야 합니다."); return; }

CourseUserDao cu = new CourseUserDao();
UserDao user = new UserDao();

DataSet info = cu.query(
	" SELECT a.*, b.course_nm, c.user_nm "
	+ " FROM " + cu.table + " a "
	+ " INNER JOIN " + course.table + " b ON a.course_id = b.id "
	+ " LEFT JOIN " + user.table + " c ON a.user_id = c.id "
	+ " WHERE a.id = " + id + " AND a.close_yn = 'Y' AND complete_yn = 'Y' "
);

if(!info.next()) { m.jsErrClose("수강 정보를 찾을 수 없습니다."); return; }

info.put("start_date_conv", m.time("yyyy년 MM월 dd일", info.s("start_date")));
info.put("end_date_conv", m.time("yyyy년 MM월 dd일", info.s("end_date")));
info.put("course_nm_conv", m.cutString(m.htmlToText(info.s("course_nm")), 48));
info.put("total_score", m.nf(info.d("total_score"), 0));
info.put("certificate_file_url", Config.getDataUrl() + "/file/" + siteinfo.i("id") + "/site/certificate_file");

//출력
p.setLayout("pop2");
p.setBody("management.pop_certificate");
p.setVar("p_title", "증명서발급관리");
p.setVar(info);

p.setVar("certificate_no", m.time("yyyy.MM.dd", info.s("start_date")) + "-" + m.strrpad(id+"", 5, "0"));
p.setVar("today", m.time("yyyy년 MM월 dd일"));

p.display();

%>