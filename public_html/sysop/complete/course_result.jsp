<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(76, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int cid = m.ri("cid");
if(cid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");
CourseUserDao courseUser = new CourseUserDao();
UserDao user = new UserDao();

//카테고리
DataSet categories = category.getList(siteId);

//정보-과정
DataSet cinfo = course.find(
	"id = " + cid + " AND status != -1 AND site_id = " + siteId + ""
	+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
);
if(!cinfo.next()) { m.jsError("해당 정보가 없습니다."); return; }
cinfo.put("cate_name", category.getTreeNames(cinfo.i("category_id")));
cinfo.put("status_conv", m.getItem(cinfo.s("status"), course.statusList));
cinfo.put("close_date_conv", m.time("yyyy-MM-dd HH:mm", cinfo.s("close_date")));

cinfo.put("std_progress", m.nf(cinfo.i("assign_progress") * cinfo.i("limit_progress") / 100, 2));
cinfo.put("std_exam", m.nf(cinfo.i("assign_exam") * cinfo.i("limit_exam") / 100, 2));
cinfo.put("std_homework", m.nf(cinfo.i("assign_homework") * cinfo.i("limit_homework") / 100, 2));
cinfo.put("std_forum", m.nf(cinfo.i("assign_forum") * cinfo.i("limit_forum") / 100, 2));
cinfo.put("std_etc", m.nf(cinfo.i("assign_etc") * cinfo.i("limit_etc") / 100, 2));

cinfo.put("alltimes_block", "A".equals(cinfo.s("course_type")));
cinfo.put("study_sdate_conv", m.time("yyyy.MM.dd", cinfo.s("study_sdate")));
cinfo.put("study_edate_conv", m.time("yyyy.MM.dd", cinfo.s("study_edate")));
cinfo.put("display_conv", cinfo.b("display_yn") ? "정상" : "숨김");

//정보-수강인원
DataSet stat = courseUser.query(
	"SELECT COUNT(*) u_cnt"
	+ ", SUM(CASE WHEN a.close_yn = 'Y' AND a.complete_yn = 'Y' THEN 1 ELSE 0 END) c_cnt"
	+ ", SUM(CASE WHEN a.total_score >= 90.0 THEN 1 ELSE 0 END) p90_cnt"
	+ ", SUM(CASE WHEN a.total_score < 90.0 AND a.total_score >= 80.0 THEN 1 ELSE 0 END) p80_cnt"
	+ ", SUM(CASE WHEN a.total_score < 80.0 AND a.total_score >= 70.0 THEN 1 ELSE 0 END) p70_cnt"
	+ ", SUM(CASE WHEN a.total_score < 70.0 AND a.total_score >= 60.0 THEN 1 ELSE 0 END) p60_cnt"
	+ ", SUM(CASE WHEN a.total_score < 60.0 THEN 1 ELSE 0 END) else_cnt"
	+ " FROM " + courseUser.table + " a "
	+ " WHERE a.course_id = " + cid + " AND a.status IN (1,3) "
);
if(!stat.next()) stat.addRow();
if(stat.i("u_cnt") == 0) {
	stat.put("p90_cnt", 0); stat.put("p90_rate", 0.0);
	stat.put("p80_cnt", 0); stat.put("p80_rate", 0.0);
	stat.put("p70_cnt", 0); stat.put("p70_rate", 0.0);
	stat.put("p60_cnt", 0); stat.put("p60_rate", 0.0);
	stat.put("else_cnt", 0); stat.put("else_rate", 0.0);
	stat.put("else_rate2", 100.0);
	stat.put("t_rate", 0.0);
} else {
	stat.put("p90_rate", m.nf(Math.round(stat.d("p90_cnt") * 100 / stat.i("u_cnt")), 1));
	stat.put("p80_rate", m.nf(Math.round(stat.d("p80_cnt") * 100 / stat.i("u_cnt")), 1));
	stat.put("p70_rate", m.nf(Math.round(stat.d("p70_cnt") * 100 / stat.i("u_cnt")), 1));
	stat.put("p60_rate", m.nf(Math.round(stat.d("p60_cnt") * 100 / stat.i("u_cnt")), 1));
	stat.put("else_rate", m.nf(Math.round(stat.d("else_cnt") * 100 / stat.i("u_cnt")), 1));
	stat.put("else_rate2", stat.s("else_rate"));
	stat.put("t_rate", 100.0);
}

stat.put("u_cnt_conv", m.nf(stat.i("u_cnt")));
stat.put("c_cnt_conv", m.nf(stat.i("c_cnt")));
cinfo.put("complete_rate", m.nf(stat.i("u_cnt") > 0 ? stat.d("c_cnt") / stat.i("u_cnt") * 100 : 0.0, 1));

for(int i = 0; i < courseUser.scoreFields.length; i++) {
	cinfo.put("assign_" + courseUser.scoreFields[i], cinfo.i("assign_" + courseUser.scoreFields[i]));
	cinfo.put("total_assign", cinfo.i("total_assign") + cinfo.i("assign_" + courseUser.scoreFields[i]));
	cinfo.put("limit_" + courseUser.scoreFields[i], cinfo.i("limit_" + courseUser.scoreFields[i]));
	cinfo.put("total_limit", cinfo.i("total_limit") + cinfo.i("limit_" + courseUser.scoreFields[i]));
}

//출력
p.setLayout("pop");
p.setBody("complete.course_result");
p.setVar("p_title", "성적분포");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("course", cinfo);
p.setVar("stat", stat);
p.display();

%>