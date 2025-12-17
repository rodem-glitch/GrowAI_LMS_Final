<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 자료 탭에서, 과목에 연결된 자료(LM_LIBRARY + LM_COURSE_LIBRARY)를 운영 DB 기준으로 보여주기 위함입니다.

int courseId = m.ri("course_id");
if(0 == courseId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseDao course = new CourseDao();
LibraryDao library = new LibraryDao();
CourseLibraryDao courseLibrary = new CourseLibraryDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 자료를 조회할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet cinfo = course.find("id = " + courseId + " AND site_id = " + siteId + " AND status != -1");
if(!cinfo.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 과목이 없습니다.");
	result.print();
	return;
}

DataSet list = courseLibrary.query(
	" SELECT l.id library_id, l.library_nm, l.content, l.library_file, l.library_link, l.download_cnt, l.reg_date "
	+ " FROM " + courseLibrary.table + " cl "
	+ " INNER JOIN " + library.table + " l ON cl.library_id = l.id AND l.site_id = " + siteId + " AND l.status != -1 "
	+ " WHERE cl.course_id = " + courseId + " AND cl.site_id = " + siteId + " "
	+ " ORDER BY l.id DESC "
);

while(list.next()) {
	list.put("upload_date_conv", !"".equals(list.s("reg_date")) ? m.time("yyyy.MM.dd", list.s("reg_date")) : "-");

	String filename = list.s("library_file");
	list.put("file_url", !"".equals(filename) ? m.getUploadUrl(filename) : "");
	list.put("file_size_conv", "-");
	if(!"".equals(filename)) {
		try {
			File f1 = new File(m.getUploadPath(filename));
			if(f1.exists()) {
				long bytes = f1.length();
				double mb = bytes / (1024.0 * 1024.0);
				list.put("file_size_conv", (mb >= 1.0 ? m.nf(mb, 1) + "MB" : m.nf(bytes / 1024.0, 1) + "KB"));
			}
		} catch(Exception ignore) {}
	}
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>

