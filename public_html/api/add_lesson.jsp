<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

String contentName = m.request("content");
String type = m.request("type", "04");
String name = m.request("name");
String url = m.request("url");
int time = m.reqInt("time");
int width = m.reqInt("width", 800);
int height = m.reqInt("height", 600);
String author = m.request("author");
String uid = m.request("user_id");

UserDao user = new UserDao();
ContentDao content = new ContentDao();
LessonDao lesson = new LessonDao();
//ContentLessonDao_ clesson_ = new ContentLessonDao_();

DataSet cInfo = content.find("site_id = " + siteId + " AND content_nm = '" + contentName + "' AND status = 1");
if(!cInfo.next()) {
	_ret.put("ret_code", "100");
	_ret.put("ret_msg", "This content does not exists");
	out.print(_ret.toString());
	return;
}

if("".equals(type) || "".equals(name) || "".equals(url)) {
	_ret.put("ret_code", "201");
	_ret.put("ret_msg", "Lesson information does not valid");
	out.print(_ret.toString());
	return;
}

int newId = lesson.getSequence();
lesson.item("id", newId);
lesson.item("site_id", siteId);
lesson.item("content_id", cInfo.i("id"));
lesson.item("onoff_type", "N");
lesson.item("lesson_type", type);
lesson.item("lesson_nm", name);
lesson.item("author", author);
lesson.item("start_url", url);
lesson.item("mobile_a", url);
lesson.item("mobile_i", url);
lesson.item("total_time", time);
lesson.item("complete_time", 0);
lesson.item("content_width", width);
lesson.item("content_height", height);
lesson.item("manager_id", user.getOneInt("SELECT id FROM " + user.table + " WHERE login_id = '" + uid + "'"));
lesson.item("reg_date", m.time());
lesson.item("status", 1);
if(!lesson.insert()) {
	_ret.put("ret_code", "200");
	_ret.put("ret_msg", "lesson insert error");
	out.print(_ret.toString());
	return;
}
/*
int chapter = clesson_.getOneInt("SELECT max(chapter) FROM " + clesson_.table + " WHERE content_id = " + cInfo.i("id")) + 1;

clesson_.item("content_id", cInfo.i("id"));
clesson_.item("lesson_id", newId);
clesson_.item("site_id", siteId);
clesson_.item("chapter", chapter);
if(!clesson_.insert()) {
	_ret.put("ret_code", "300");
	_ret.put("ret_msg", "content_lesson insert error");
	out.print(_ret.toString());
	return;
}
*/

out.print(_ret.toString());
%>