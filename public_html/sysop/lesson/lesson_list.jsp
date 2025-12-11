<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(30, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
LessonDao lesson = new LessonDao();
ContentDao content = new ContentDao();
CourseLessonDao courseLesson = new CourseLessonDao();

//폼체크
f.addElement("s_content", null, null);
f.addElement("s_type", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : f.getInt("s_listnum", 20));
lm.setTable(
	lesson.table + " a "
	+ " LEFT JOIN " + content.table + " c ON c.id = a.content_id "
);
lm.setFields(
	" a.*, c.id content_id, c.content_nm "
	+ ("excel".equals(m.rs("mode")) && null != f.getArr("s_excel_fields") && Arrays.asList(f.getArr("s_excel_fields")).contains("use_course_idx")
		? ", (SELECT GROUP_CONCAT(course_id) FROM " + courseLesson.table + " WHERE lesson_id = a.id) as use_course_idx "
		: ""
	)
);
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId);
lm.addWhere("a.onoff_type = 'N'"); //오프라인
lm.addSearch("a.status", f.get("s_status"));
lm.addSearch("a.content_id", f.get("s_content"));
lm.addSearch("a.lesson_type", f.get("s_type"));
//lm.addWhere("a.lesson_type != '" + ("W".equals(siteinfo.s("ovp_vendor")) ? "05" : "01") + "'");
if("C".equals(userKind)) lm.addWhere("a.manager_id = " + userId);
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.lesson_nm, a.author, a.start_url, c.content_nm", f.get("s_keyword"), "LIKE");
lm.setOrderBy("a.use_yn desc, " + (!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC"));

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
//	list.put("del_param", m.urlencode(Base64Coder.encode("id='" + list.s("id") + "'"))); //복수선택삭제 사용시만	
	list.put("status_conv", m.getItem(list.s("status"), lesson.statusList));
	list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), lesson.allTypes));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("total_time_conv", m.nf(list.i("total_time")));
	list.put("complete_time_conv", m.nf(list.i("complete_time")));
	list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm"), 60));
	list.put("pc_block", !"".equals(list.s("start_url")));
	list.put("mobile_block", !"".equals(list.s("mobile_a")));
	if(1 > list.i("content_id")) list.put("content_nm_conv", "[미지정]");
	else list.put("content_nm_conv", m.cutString(list.s("content_nm"), 20));
}

//엑셀
String[] exFields = new String[] { "__ord=>No", "id=>고유값", "content_nm=>강의그룹명", "lesson_nm=>강의명", "lesson_type=>콘텐츠타입", "start_url=>시작파일", "total_page=>총페이지", "total_time=>학습시간", "complete_time=>인정시간", "content_width=>창넓이", "content_height=>창높이", "reg_date=>등록일", "use_course_idx=>사용과정ID", "status=>상태" };
if("excel".equals(m.rs("mode"))) {
	String[] outputFields = f.getArr("s_excel_fields");
	if(null == outputFields) { m.jsError("출력항목을 선택해주세요."); return; }
	for(int i = 0; i < outputFields.length; i++) outputFields[i] = outputFields[i] + "=>" + m.getItem(outputFields[i], exFields);
	ExcelWriter ex = new ExcelWriter(response, "온라인강의관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, outputFields, "온라인강의관리(" + m.time("yyyy-MM-dd"));
	ex.write();
	return;
}

//출력
p.setBody("lesson.lesson_list" + ("frame".equals(m.rs("mode")) ? "_frame" : ""));
p.setVar("form_script", f.getScript());
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("wecandeo_block", "W".equals(siteinfo.s("ovp_vendor")));
p.setVar("catenoid_block", "C".equals(siteinfo.s("ovp_vendor")));
p.setVar("live_block", "Y".equals(SiteConfig.s("kollus_live_yn")));
p.setVar("doczoom_block", "Y".equals(SiteConfig.s("doczoom_yn")));

p.setLoop("excel_fields", m.arr2loop(exFields));
p.setLoop("types", m.arr2loop("W".equals(siteinfo.s("ovp_vendor")) ? lesson.lessonTypes : lesson.catenoidLessonTypes));
p.setLoop("status_list", m.arr2loop(lesson.statusList));
p.setLoop("content_list", content.find("status != -1 AND site_id = " + siteId, "*", "content_nm ASC"));
p.display();

%>