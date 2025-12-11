<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(712, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//기본키
int tagId = m.ri("tid");
if(tagId < 1) { m.jsErrClose("기본키는 반드시 지정하여야 합니다."); return; }

//객체
TagDao tag = new TagDao(siteId);
TagModuleDao tagModule = new TagModuleDao("course");
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");

//폼체크
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_onofftype", null, null);

//정보
DataSet info = tag.find("id = ? AND status = 1 AND site_id = ?", new Object[] { tagId, siteId });
if(!info.next()) { m.jsErrClose("해당 태그 정보가 없습니다."); return; }

//카테고리
try {
	category.getList(siteId);
} catch (Exception e) {
	Malgn.errorLog("{tag.course_list} category getList error", e);
}

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	tagModule.table + " tm "
	+ " INNER JOIN " + course.table + " c ON c.id = tm.module_id AND c.status != -1 "
);
lm.setFields(
	"tm.tag_id, tm.module_id course_id "
	+ ", c.year, c.step, c.course_nm, c.category_id, c.onoff_type, c.course_type "
	+ ", c.request_sdate, c.request_edate, c.study_sdate, c.study_edate, c.course_file "
);
lm.addWhere("tm.tag_id = " + tagId + "");
lm.addWhere("tm.module = 'course'");
if("C".equals(userKind)) lm.addWhere("c.id IN (" + manageCourses + ")");
lm.addSearch("c.onoff_type", f.get("s_onofftype"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("c.course_nm, c.id", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "c.reg_date DESC, c.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", Malgn.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("onoff_type_conv", Malgn.getItem(list.s("onoff_type"), course.onoffPackageTypes));

	list.put("package_block", "P".equals(list.s("onoff_type")));
	list.put("alltimes_block", "A".equals(list.s("course_type")));
	list.put("regular_block", "R".equals(list.s("course_type")));
	list.put("request_sdate_conv", Malgn.time("yyyy.MM.dd HH:mm", list.s("request_sdate")));
	list.put("request_edate_conv", Malgn.time("yyyy.MM.dd HH:mm", list.s("request_edate")));
	list.put("study_sdate_conv", Malgn.time("yyyy.MM.dd", list.s("study_sdate")));
	list.put("study_edate_conv", Malgn.time("yyyy.MM.dd", list.s("study_edate")));
	list.put("main_img_url", m.getUploadUrl(list.s("course_file")));

	try {
		list.put("cate_name", category.getTreeNames(list.i("category_id")));
	} catch (Exception e) {
		Malgn.errorLog("{tag.course_list} category getTreeNames error", e);
	}
}

//출력
p.setLayout("pop");
p.setBody("tag.course_list");
p.setVar("p_title", "태그 [ " + info.s("tag_nm") + " ] 사용과정");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());
p.setVar("list_total_num", Malgn.nf(lm.getTotalNum()));

p.setLoop("onoff_types", Malgn.arr2loop(course.onoffPackageTypes));

p.display();

%>