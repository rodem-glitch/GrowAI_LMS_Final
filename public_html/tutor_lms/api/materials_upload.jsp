<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 자료 업로드에서, 자료(LM_LIBRARY)를 생성하고 해당 과목(LM_COURSE_LIBRARY)에 연결해야 합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

// 왜: 자료 업로드는 파일을 포함할 수 있어 `multipart/form-data`(FormData)로 들어옵니다.
//     이때는 `m.ri()`(request.getParameter 기반)로는 값을 못 읽는 경우가 있어,
//     업로드 파라미터 파싱을 담당하는 Form(`f`)에서 먼저 읽고, 필요 시 m.ri로 보완합니다.
int courseId = f.getInt("course_id");
if(0 == courseId) courseId = m.ri("course_id");
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
		result.put("rst_message", "해당 과목에 자료를 업로드할 권한이 없습니다.");
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

//필수값
f.addElement("title", null, "hname:'자료명', required:'Y'");
f.addElement("content", "", "hname:'자료설명'");
f.addElement("library_link", "", "hname:'자료링크'");

if(!f.validate()) {
	result.put("rst_code", "1000");
	result.put("rst_message", "필수값이 누락되었습니다.");
	result.print();
	return;
}

String title = f.get("title").trim();
String link = f.get("library_link").trim();
String filename = "";

if(null != f.getFileName("library_file")) {
	File f1 = f.saveFile("library_file");
	if(f1 != null) filename = f.getFileName("library_file");
}

//왜: 파일/링크 둘 다 없으면 자료로서 의미가 없습니다.
if("".equals(filename) && "".equals(link)) {
	result.put("rst_code", "1100");
	result.put("rst_message", "자료 파일 또는 링크 중 하나는 필요합니다.");
	result.print();
	return;
}

int newId = library.getSequence();
library.item("id", newId);
library.item("site_id", siteId);
library.item("category_id", 0);
library.item("library_nm", title);
library.item("content", f.get("content"));
library.item("library_file", filename);
library.item("library_link", link);
library.item("download_cnt", 0);
library.item("manager_id", userId);
library.item("reg_date", m.time("yyyyMMddHHmmss"));
library.item("status", 1);

if(!library.insert()) {
	//업로드 파일이 남지 않도록 정리(가능한 경우)
	try { if(!"".equals(filename)) m.delFile(m.getUploadPath(filename)); } catch(Exception ignore) {}
	result.put("rst_code", "2000");
	result.put("rst_message", "자료 저장 중 오류가 발생했습니다.");
	result.print();
	return;
}

courseLibrary.item("course_id", courseId);
courseLibrary.item("library_id", newId);
courseLibrary.item("site_id", siteId);
if(!courseLibrary.insert()) {
	library.item("status", -1);
	library.update("id = " + newId);
	result.put("rst_code", "2001");
	result.put("rst_message", "과목 연결 저장 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", newId);
result.print();

%>
