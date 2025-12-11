<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
int cid = m.ri("cid");
if(id == 0 || cid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
LessonDao lesson = new LessonDao();
FileDao file = new FileDao();

//정보-과정
DataSet cinfo = course.find(
	"id = " + cid + " AND status != -1 AND site_id = " + siteId + ""
	+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
);
if(!cinfo.next()) { m.jsError("해당 과정 정보가 없습니다."); return; }

//정보
DataSet info = lesson.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

info.put("twoway_block", "T".equals(info.s("onoff_type")));
info.put("online_block", "N".equals(info.s("onoff_type")) || info.b("twoway_block"));

info.put("type_conv", m.getItem(info.s("lesson_type"), "W".equals(siteinfo.s("ovp_vendor")) ? lesson.types : lesson.catenoidTypes));
info.put("status_conv", m.getItem(info.s("status"), lesson.statusList));
info.put("description_conv", m.nl2br(info.s("description")));
info.put("lesson_file_conv", m.encode(info.s("lesson_file")));
info.put("lesson_file_ek", m.encrypt(info.s("lesson_file") + m.time("yyyyMMdd")));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));

//목록-교안
DataSet files = file.getFileList(id, "lesson");
while(files.next()) {
	files.put("file_ext", file.getFileExt(files.s("filename")));
	files.put("filename_conv", m.urlencode(Base64Coder.encode(files.s("filename"))));
	files.put("ext", file.getFileIcon(files.s("filename")));
	files.put("ek", m.encrypt(files.s("id")));
	files.put("sep", !files.b("__last") ? "<br>" : "");
}

//출력
p.setLayout("pop");
p.setBody("course.lesson_view");
p.setVar("p_title", "강의 조회");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("cid, id"));
p.setVar("form_script", f.getScript());

p.setVar("course", cinfo);
p.setVar(info);
p.setLoop("files", files);

p.display();