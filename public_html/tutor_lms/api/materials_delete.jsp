<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 자료 탭에서, 과목에서 자료를 제거(연결 해제)해야 합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
int libraryId = m.ri("library_id");
if(0 == courseId || 0 == libraryId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id, library_id가 필요합니다.");
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
		result.put("rst_message", "해당 과목의 자료를 삭제할 권한이 없습니다.");
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

if(0 >= courseLibrary.findCount("course_id = " + courseId + " AND library_id = " + libraryId + " AND site_id = " + siteId)) {
	result.put("rst_code", "4041");
	result.put("rst_message", "해당 자료가 과목에 연결되어 있지 않습니다.");
	result.print();
	return;
}

DataSet linfo = library.find("id = " + libraryId + " AND site_id = " + siteId + " AND status != -1");
if(!linfo.next()) {
	result.put("rst_code", "4042");
	result.put("rst_message", "자료 정보가 없습니다.");
	result.print();
	return;
}

if(!courseLibrary.delete("course_id = " + courseId + " AND library_id = " + libraryId + " AND site_id = " + siteId)) {
	result.put("rst_code", "2000");
	result.put("rst_message", "삭제 중 오류가 발생했습니다.");
	result.print();
	return;
}

//왜: 다른 과목에서 쓰지 않는 자료이고, 내가 올린 자료라면 soft-delete + 파일 정리까지 합니다.
try {
	if(0 >= courseLibrary.findCount("library_id = " + libraryId + " AND site_id = " + siteId)) {
		if(isAdmin || linfo.i("manager_id") == userId) {
			library.item("status", -1);
			library.update("id = " + libraryId + " AND site_id = " + siteId);
			if(!"".equals(linfo.s("library_file"))) m.delFile(m.getUploadPath(linfo.s("library_file")));
		}
	}
} catch(Exception ignore) {}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", libraryId);
result.print();

%>

