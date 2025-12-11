<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(29, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
int cid = m.ri("cid");
if(id == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
ContentDao content = new ContentDao();
LessonDao lesson = new LessonDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseDao course = new CourseDao();
WebtvDao webtv = new WebtvDao();
UserDao user = new UserDao();
FileDao file = new FileDao();

//정보
DataSet info = lesson.query(
	" SELECT a.*, u.user_nm manager_name "
	+ " FROM " + lesson.table + " a "
	+ " LEFT JOIN " + content.table + " c ON a.content_id = c.id AND c.site_id IN (0," + siteId + ")"
	+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
	+ " WHERE a.id = " + id + " AND a.status != -1 AND a.site_id = " + siteId
	+ (cid > 0 ? " AND a.content_id = " + cid + "" : "")
);
if(!info.next()) { m.jsErrClose("해당 강의 정보가 없습니다."); return; }

//이동-오프라인강의
if("F".equals(info.s("onoff_type"))) {
	m.jsReplace("../offline/lesson_modify.jsp?id=" + id + "&ch=pop");
	return;
} else if("T".equals(info.s("onoff_type"))) {
	m.jsReplace("../twoway/lesson_modify.jsp?id=" + id + "&ch=pop");
	return;
}

//수정가능여부
boolean isModify = "S".equals(userKind) || userId == info.i("manager_id");
boolean sysAIChat = "Y".equals(SiteConfig.s("sys_ai_chat_yn")) && sysViewerVersion == 2;

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"lesson_"});

//폼체크
f.addElement("content_id", info.s("content_id"), "hname:'강의그룹', required:'Y'");
f.addElement("lesson_nm", info.s("lesson_nm"), "hname:'강의명', required:'Y'");
f.addElement("total_time", info.i("total_time"), "hname:'학습시간', option:'number'");
f.addElement("manager_nm", info.s("user_nm"), "hname:'담당자아이디'");
f.addElement("description", info.s("description"), "hname:'설명'");
f.addElement("lesson_type", info.s("lesson_type"), "hname:'동영상타입', required:'Y'");
f.addElement("start_url", info.s("start_url"), "hname:'시작파일'");
f.addElement("mobile_url", info.s("mobile_a"), "hname:'시작파일'");
f.addElement("short_url", info.s("short_url"), "hname:'숏폼파일'");
f.addElement("total_page", info.i("total_page"), "hname:'총페이지', option:'number'");
f.addElement("complete_time", info.i("complete_time"), "hname:'인정시간', option:'number'");
f.addElement("author", info.s("author"), "hname:'저작자'");
f.addElement("content_height", info.i("content_height"), "hname:'창높이', option:'number'");
f.addElement("content_width", info.i("content_width"), "hname:'창넓이', option:'number'");
if(siteconfig.b("lesson_chat_yn")) f.addElement("chat_yn", info.s("chat_yn"), "hname:'라이브채팅'");
if(sysAIChat) f.addElement("ai_chat_yn", info.s("ai_chat_yn"), "hname:'AI채팅'");
if(!courseManagerBlock) f.addElement("manager_id", info.s("manager_id"), "hname:'담당자'");
f.addElement("manager_name", info.s("manager_name"), "hname:'담당자'");
f.addElement("use_yn", info.s("use_yn"), "hname:'활성여부'");
f.addElement("status", info.i("status"), "hname:'상태', required:'Y'");

if(m.isPost() && f.validate()) {

	//if(!isModify) return;

	String useYn = f.get("use_yn", "N");

	lesson.item("content_id", f.getInt("content_id"));
	lesson.item("lesson_nm", f.get("lesson_nm"));
	lesson.item("lesson_type", f.get("lesson_type"));
	lesson.item("start_url", f.get("start_url"));
	lesson.item("mobile_a", f.get("mobile_url"));
	lesson.item("mobile_i", f.get("mobile_url"));
	lesson.item("short_url", f.get("short_url"));
	lesson.item("total_page", f.getInt("total_page"));
	lesson.item("total_time", f.getInt("total_time"));
	lesson.item("complete_time", f.getInt("complete_time"));
	lesson.item("content_width", f.getInt("content_width"));
	lesson.item("content_height", f.getInt("content_height"));
	lesson.item("author", f.get("author"));
	lesson.item("description", f.get("description"));
	lesson.item("chat_yn", siteconfig.b("lesson_chat_yn") && "04".equals(f.get("lesson_type")) ? f.get("chat_yn") : "N"); //외부링크에서만 미니톡 채팅 사용
	lesson.item("ai_chat_yn", sysAIChat ? f.get("ai_chat_yn", "N") : "N");
	if(!courseManagerBlock) lesson.item("manager_id", f.getInt("manager_id"));
	lesson.item("use_yn", useYn);
	lesson.item("status", f.getInt("status"));

	if(!useYn.equals(info.s("use_yn"))) {
		lesson.item("sort", lesson.getMaxSort(info.i("content_id"), f.get("use_yn"), siteId));
	}

	if(!lesson.update("id = " + info.i("id"))) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//순서
	if(0 < f.getInt("content_id")) lesson.autoSort(f.getInt("content_id"), siteId);

	//채널등록
	//if(siteconfig.b("lesson_chat_yn") && "04".equals(f.get("lesson_type")) && !"Y".equals(info.s("chat_yn")) && "Y".equals(f.get("chat_yn"))) {
	if(siteconfig.b("lesson_chat_yn") && "04".equals(f.get("lesson_type")) && "Y".equals(f.get("chat_yn"))) {
		DataSet cllist = courseLesson.query(
			"SELECT a.*, l.lesson_nm, c.course_nm "
			+ " FROM " + courseLesson.table + " a "
			+ " LEFT JOIN " + lesson.table + " l on a.lesson_id = l.id AND l.site_id = " + siteId
			+ " LEFT JOIN " + course.table + " c on a.course_id = c.id AND c.site_id = " + siteId
			+ " WHERE a.lesson_id = " + id + " AND a.site_id = " + siteId
		);

		DataSet wlist = webtv.find("lesson_id = ? AND site_id = ? AND status = ?", new Object[] {id, siteId, 1});
		String categoryNm = siteinfo.s("site_nm");
		while(cllist.next()) {
			String channelId = lesson.getChannelId(siteinfo.s("ftp_id"), siteId, cllist.i("course_id"), cllist.i("lesson_id"), "c");
			lesson.insertChannel(channelId, categoryNm, "채팅방");
		}

		while(wlist.next()) {
			String channelId = lesson.getChannelId(siteinfo.s("ftp_id"), siteId, wlist.i("id"), wlist.i("lesson_id"), "w");
			lesson.insertChannel(channelId, categoryNm, "채팅방");
		}
	}

	//이동
	if("direct".equals(m.rs("mode"))) {
		m.js("try { parent.opener.document.forms['form1']['lesson_nm'].value = '" + m.addSlashes(f.get("lesson_nm")) + "'; } catch(e) { } parent.window.close();");
	} else {
		out.print("<script>try { parent.opener.location.reload(); } catch(e) { } parent.window.close();</script>");
	}
	return;
}

//포멧팅
//info.put("type_conv", m.getItem(info.s("lesson_type"), "W".equals(siteinfo.s("ovp_vendor")) ? lesson.lessonTypes : lesson.catenoidLessonTypes));
info.put("type_conv", m.getItem(info.s("lesson_type"), lesson.allLessonTypes));
info.put("status_conv", m.getItem(info.s("status"), lesson.statusList));
info.put("description_conv", m.nl2br(info.s("description")));

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
p.setVar("p_title", "온라인강의관리");
p.setBody("content.lesson_insert");
//if(!isModify) p.setBody("content.lesson_view");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id, type"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);
p.setLoop("files", files);

p.setVar("SITE_CONFIG", siteconfig);
p.setVar("aichat_block", sysAIChat);
p.setVar("wecandeo_block", -1 < request.getServerName().indexOf("malgn.co.kr") || "W".equals(siteinfo.s("ovp_vendor")));
p.setVar("catenoid_block", -1 < request.getServerName().indexOf("malgn.co.kr") || "C".equals(siteinfo.s("ovp_vendor")));
p.setVar("live_block", -1 < request.getServerName().indexOf("malgn.co.kr") || "Y".equals(SiteConfig.s("kollus_live_yn")));
p.setVar("doczoom_block", "Y".equals(SiteConfig.s("doczoom_yn")));
p.setVar("lesson_id", id);
//p.setLoop("lesson_types", m.arr2loop("W".equals(siteinfo.s("ovp_vendor")) ? lesson.lessonTypes : lesson.catenoidLessonTypes));
p.setLoop("lesson_types", m.arr2loop(lesson.allLessonTypes));
p.setLoop("managers", user.getManagers(siteId));
p.setLoop("use_types", m.arr2loop(lesson.useTypes));
p.setLoop("chat_use_types", m.arr2loop(lesson.chatUseTypes));
p.setLoop("status_list", m.arr2loop(lesson.statusList));
p.setLoop("content_list", content.find(("C".equals(userKind) ? "manager_id = " + userId + " AND " : "") + "status != -1 AND site_id = " + siteId + "", "*", "content_nm ASC"));
p.display();

%>