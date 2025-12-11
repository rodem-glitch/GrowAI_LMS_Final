<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseTutorDao courseTutor = new CourseTutorDao();
LmCategoryDao category = new LmCategoryDao("course");
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();
MCal mcal = new MCal(); mcal.yearRange = 10;

//폼체크
f.addElement("s_req_sdate", null, null);
f.addElement("s_req_edate", null, null);
f.addElement("s_std_sdate", null, null);
f.addElement("s_std_edate", null, null);

f.addElement("s_grade", null, null);
f.addElement("s_term", null, null);
f.addElement("s_subject", null, null);
f.addElement("s_year", null, null);
f.addElement("s_category", null, null);
f.addElement("s_onofftype", null, null);
f.addElement("s_type", null, null);
f.addElement("s_sale_yn", null, null);
f.addElement("s_display_yn", null, null);
f.addElement("s_close", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//카테고리
DataSet categories = category.getList(siteId);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 60000 : f.getInt("s_listnum", 20));
lm.setTable(course.table + " a");
lm.setFields("a.*"
	+ ", (SELECT COUNT(*) FROM " + courseUser.table + " cu "
		+ " INNER JOIN " + user.table + " u ON cu.user_id = u.id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
		+ " WHERE cu.course_id = a.id AND cu.status IN (1,3) "
	+ " ) user_cnt ");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
if("C".equals(userKind)) lm.addWhere("a.id IN (" + manageCourses + ")");
lm.addSearch("a.year", f.get("s_year"));
lm.addSearch("a.grade", f.get("s_grade"));
lm.addSearch("a.term", f.get("s_term"));
lm.addSearch("a.subject", f.get("s_subject"));
lm.addSearch("a.course_type", f.get("s_type"));
lm.addSearch("a.onoff_type", f.get("s_onofftype"));
lm.addSearch("a.sale_yn", f.get("s_sale_yn"));
lm.addSearch("a.display_yn", f.get("s_display_yn"));
lm.addSearch("a.close_yn", f.get("s_close"));
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_req_sdate"))) lm.addWhere("a.request_edate >= '" + m.time("yyyyMMdd", f.get("s_req_sdate")) + "'");
if(!"".equals(f.get("s_req_edate"))) lm.addWhere("a.request_sdate <= '" + m.time("yyyyMMdd", f.get("s_req_edate")) + "'");
if(!"".equals(f.get("s_std_sdate"))) lm.addWhere("a.study_edate >= '" + m.time("yyyyMMdd", f.get("s_std_sdate")) + "'");
if(!"".equals(f.get("s_std_edate"))) lm.addWhere("a.study_sdate <= '" + m.time("yyyyMMdd", f.get("s_std_edate")) + "'");
if(!"".equals(f.get("s_category"))) {
	lm.addWhere("a.category_id IN ( '" + m.join("','", category.getChildNodes(f.get("s_category"))) + "' )");
}
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.course_nm, a.etc1, a.etc2, a.id", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC, a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 80));
	list.put("sale_yn_conv", m.getItem(list.s("sale_yn"), course.saleYn));
	list.put("display_yn_conv", m.getItem(list.s("display_yn"), course.displayYn));
	list.put("status_conv", m.getItem(list.s("status"), course.statusList));

	list.put("price_conv", m.nf(list.i("price")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("course_file_url", !"".equals(list.s("course_file")) ? siteDomain + m.getUploadUrl(list.s("course_file")) : "");
	list.put("cate_name", category.getTreeNames(list.i("category_id")));
	list.put("type_conv", m.getItem(list.s("course_type"), course.types));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffPackageTypes));

	list.put("package_block", "P".equals(list.s("onoff_type")));
	list.put("alltimes_block", "A".equals(list.s("course_type")));
	list.put("regular_block", "R".equals(list.s("course_type")));
	list.put("copy_block", !list.b("package_block"));
	list.put("request_sdate_conv", m.time("yyyy.MM.dd", list.s("request_sdate")));
	list.put("request_edate_conv", m.time("yyyy.MM.dd", list.s("request_edate")));
	list.put("study_sdate_conv", m.time("yyyy.MM.dd", list.s("study_sdate")));
	list.put("study_edate_conv", m.time("yyyy.MM.dd", list.s("study_edate")));
	
	list.put("tutor_nm_conv", courseTutor.getTutorName(list.i("id")));

	list.put("grade_conv", Malgn.getItem(list.s("grade"), course.grades));
	list.put("term_conv", Malgn.getItem(list.s("term"), course.terms));
	list.put("subject_conv", Malgn.getItem(list.s("subject"), course.subjects));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "과정개설관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>과정아이디", "course_cd=>마이그레이션용과정코드", "course_nm=>과정명", "cate_name=>카테고리", "tutor_nm_conv=>강사", "lesson_day=>수강일수", "lesson_time=>수강시간(시)", "list_price=>정가", "price=>수강료(실결제가)", "credit=>학점", "assign_progress=>출석(진도) 배점", "assign_exam=>평가 배점", "assign_homework=>과제 배점", "assign_forum=>토론 배점", "assign_etc=>기타 배점", "limit_progress=>출석(진도) 수료기준", "limit_exam=>평가 수료기준", "limit_homework=>과제 수료기준", "limit_forum=>토론 수료기준", "limit_etc=>기타 수료기준", "limit_total_score=>총점 수료기준", "limit_people_yn=>수강인원제한 사용유무", "limit_people=>수강제한인원", "limit_lesson_yn=>학습차시제한 사용유무", "limit_lesson=>학습제한 강의 수", "lesson_order_yn=>진도 순차적용 여부", "class_member=>반별인원", "period_yn=>차시별 학습기간 사용여부", "restudy_yn=>복습허용유무", "restudy_day=>복습허용기간", "complete_auto_yn=>자동수료완료여부", "course_file=>메인이미지", "reg_date_conv=>등록일", "sale_yn_conv=>판매여부", "display_yn_conv=>노출여부", "status_conv=>상태"}, "과정개설관리(" + m.time("yyyy-MM-dd") +")");
	ex.write();
	return;
}

//출력
p.setBody("course.course_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("categories", categories);
p.setLoop("sale_yn", m.arr2loop(course.saleYn));
p.setLoop("display_yn", m.arr2loop(course.displayYn));
p.setLoop("status_list", m.arr2loop(course.statusList));
p.setLoop("onoff_types", m.arr2loop(course.onoffPackageTypes));

p.setLoop("types", m.arr2loop(course.types));
p.setLoop("years", mcal.getYears());
p.setVar("this_year", m.time("yyyy"));

p.setLoop("grades", m.arr2loop(course.grades));
p.setLoop("terms", m.arr2loop(course.terms));
p.setLoop("subjects", m.arr2loop(course.subjects));

p.display();

%>