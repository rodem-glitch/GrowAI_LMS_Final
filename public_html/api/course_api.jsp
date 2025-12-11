<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String courseType = m.rs("ctype");
String onoffType = m.rs("otype");
String idx = m.rs("idx");

int id = m.ri("id");
int cid = m.ri("cid");
int year = m.ri("year"); if(year < 0 || year > 9999) year = 0;
int step = m.ri("step");

String courseNm = m.rs("name");

String saleYn = m.rs("sale").toUpperCase();
String displayYn = m.rs("display").toUpperCase();

String etc1 = m.rs("etc1");
String etc2 = m.rs("etc2");
String status = m.rs("status");

//객체
UserDao user = new UserDao();
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");

//목록-카테고리
DataSet categories = category.getList(siteId);

//목록
DataSet list = null;
if(!error) {
	ArrayList<String> qs = new ArrayList<String>();

	if(!"".equals(courseType)) qs.add(courseType);
	if(!"".equals(onoffType)) qs.add(onoffType);

	if(id > 0) qs.add(id + "");
	if(year > 0) qs.add(year + "");
	if(step > 0) qs.add(step + "");

	if(!"".equals(courseNm)) qs.add("%" + courseNm + "%");
	if(!"".equals(saleYn)) qs.add(saleYn);
	if(!"".equals(displayYn)) qs.add(displayYn);
	if(!"".equals(etc1)) qs.add("%" + etc1 + "%");
	if(!"".equals(etc2)) qs.add("%" + etc2 + "%");
	if(!"".equals(status)) qs.add(status);

	//course.d(out);
	list = course.query(
		" SELECT a.id, a.year, a.step, a.course_type, a.course_file course_file_url, a.onoff_type, a.course_nm, a.request_sdate, a.request_edate, a.study_sdate, a.study_edate, a.lesson_day, a.lesson_time "
		+ " , a.list_price, a.price, a.credit, a.subtitle, a.content1_title, a.content1, a.content2_title, a.content2, a.etc1, a.etc2, a.sale_yn, a.display_yn, a.status "
		+ " FROM " + course.table + " a "
		+ " WHERE a.site_id = " + siteId + " AND a.status != -1 "

		+ (!"".equals(courseType) ? " AND a.course_type = ? " : "")
		+ (!"".equals(onoffType) ? " AND a.onoff_type = ? " : "")
		+ (!"".equals(idx) ? " AND a.id IN (" + idx + ") " : "")

		+ (id > 0 ? " AND a.id = ? " : "")
		+ (cid > 0 ? " AND a.category_id IN ('" + m.join("','", category.getChildNodes(cid + "")) + "') " : "")
		+ (year > 0 ? " AND a.year = ? " : "")
		+ (step > 0 ? " AND a.step = ? " : "")

		+ (!"".equals(courseNm) ? " AND a.course_nm LIKE ? " : "")
		+ (!"".equals(saleYn) ? " AND a.sale_yn = ? " : "")
		+ (!"".equals(displayYn) ? " AND a.display_yn = ? " : "")
		+ (!"".equals(etc1) ? " AND a.etc1 LIKE ? " : "")
		+ (!"".equals(etc2) ? " AND a.etc2 LIKE ? " : "")
		+ (!"".equals(status) ? " AND a.status = ? " : "")

		, qs.toArray()
	);
	while(list.next()) {
		if(!"".equals(list.s("course_file_url"))) {
			list.put("course_file_url", "//" + siteinfo.s("domain") + m.getUploadUrl(list.s("course_file_url")));
		} else {
			list.put("course_file_url", "//" + siteinfo.s("domain") + "/html/images/common/noimage_course.gif");
		}
	}
	_ret.put("ret_size", list.size());
}

//수정
if(!apiLog.updateLog(_ret.get("ret_code").toString())) {
	_ret.put("ret_code", "-1");
	_ret.put("ret_msg", "cannot modify db");
	list = null;
	error = true;
};

//출력
apiLog.printList(out, _ret, list);

%>