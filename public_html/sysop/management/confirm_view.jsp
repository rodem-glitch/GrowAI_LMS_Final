<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(89, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int cuid = m.ri("cuid");
if(cuid == 0 || courseId ==0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
LmCategoryDao category = new LmCategoryDao("course");
CourseUserDao courseUser = new CourseUserDao();
UserDao user = new UserDao();

//카테고리
DataSet categories = category.getList(siteId);

//정보
DataSet info = courseUser.query(
	"SELECT a.*, u.login_id, u.user_nm "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id "
	+ " WHERE a.id = " + cuid + " AND a.status = 0 "
);
if(!info.next()) { m.jsErrClose("해당 정보가 없습니다."); return; }
info.put("start_date_conv", m.time("yyyy.MM.dd", info.s("start_date")));
info.put("end_date_conv", m.time("yyyy.MM.dd", info.s("end_date")));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("status_conv", m.getItem(info.s("status"), courseUser.statusList));

//포맷팅
cinfo.put("cate_name", category.getTreeNames(cinfo.i("category_id")));
if("R".equals(cinfo.s("course_type"))) {
	cinfo.put("request_date", m.time("yyyy.MM.dd", cinfo.s("request_sdate")) + " - " + m.time("yyyy.MM.dd", cinfo.s("request_edate")));
	cinfo.put("study_date", m.time("yyyy.MM.dd", cinfo.s("study_sdate")) + " - " + m.time("yyyy.MM.dd", cinfo.s("study_edate")));
	cinfo.put("alltime_block", false);
} else if("A".equals(cinfo.s("course_type"))) {
	cinfo.put("request_date", "상시");
	cinfo.put("study_date", "상시");
	cinfo.put("alltime_block", true);
}
cinfo.put("course_nm_conv", m.cutString(cinfo.s("course_nm"), 25));
cinfo.put("course_type_conv", m.getItem(cinfo.s("course_type"), course.types));
cinfo.put("onoff_type_conv", m.getItem(cinfo.s("onoff_type"), course.onoffTypes));


//출력
p.setLayout("pop");
p.setBody("management.confirm_view");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setVar("course", cinfo);
p.display();

%>