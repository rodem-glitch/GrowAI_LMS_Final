<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(29, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int cid = m.ri("cid");
int courseId = m.ri("course_id");
String mode = m.rs("mode");
//if(cid == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
ContentDao content = new ContentDao();
LmCategoryDao category = new LmCategoryDao("course");
CourseDao course = new CourseDao();
CourseLessonDao courseLesson = new CourseLessonDao();
LessonDao lesson = new LessonDao();
WebtvDao webtv = new WebtvDao();
UserDao user = new UserDao();
FileDao file = new FileDao();

//변수
boolean sysAIChat = "Y".equals(SiteConfig.s("sys_ai_chat_yn")) && sysViewerVersion == 2;

//카테고리
DataSet categories = category.getList(siteId);

//정보-이전등록정보
DataSet ckinfo = new DataSet();
if(!"".equals(m.getCookie("REGLESSON"))) {
	int pid = m.parseInt(m.getCookie("REGLESSON"));
	ckinfo = lesson.query(
		"SELECT a.*, u.user_nm manager_name "
		+ " FROM " + lesson.table + " a "
		+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
		+ " WHERE a.id = " + pid + " AND a.status != -1 AND a.site_id = " + siteId + ""
	);
	if(!ckinfo.next()) {
		ckinfo.addRow();
		ckinfo.put("lesson_type", "W".equals(siteinfo.s("ovp_vendor")) ? "01" : "05");
	}
} else {
	ckinfo.addRow();
	ckinfo.put("lesson_type", "W".equals(siteinfo.s("ovp_vendor")) ? "01" : "05");
}

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"lesson_"});

//폼체크
f.addElement("content_id", cid, "hname:'콘텐츠'");
f.addElement("manager_nm", ckinfo.s("manager_name"), "hname:'담당자아이디'");
f.addElement("lesson_nm", null, "hname:'강의명', required:'Y'");
f.addElement("lesson_type", ckinfo.s("lesson_type"), "hname:'동영상타입', required:'Y'");
f.addElement("author", ckinfo.s("author"), "hname:'저작자'");
f.addElement("start_url", null, "hname:'시작파일(PC)'");
f.addElement("short_url", null, "hname:'숏폼'");
f.addElement("total_time", ckinfo.i("total_time"), "hname:'학습시간', option:'number'");
f.addElement("complete_time", ckinfo.i("complete_time"), "hname:'인정시간', option:'number'");
f.addElement("content_height", (0 == ckinfo.i("content_height") ? 720 : ckinfo.i("content_height")), "hname:'창높이', option:'number'");
f.addElement("content_width", (0 == ckinfo.i("content_width") ? 1280 : ckinfo.i("content_width")), "hname:'창넓이', option:'number'");
f.addElement("total_page", ckinfo.i("total_page"), "hname:'총페이지', option:'number'");
//f.addElement("lesson_file", null, "hname:'교안파일'");
f.addElement("description", null, "hname:'강의설명'");
if(siteconfig.b("lesson_chat_yn")) f.addElement("chat_yn", "N", "hname:'라이브채팅', required:'Y'");
if(sysAIChat) f.addElement("ai_chat_yn", "N", "hname:'AI채팅'");
f.addElement("use_yn", "Y", "hname:'활성여부'");
f.addElement("status", 1, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	if(cid == 0) cid = f.getInt("content_id");

	int newId = lesson.getSequence();
	String useYn = f.get("use_yn", "N");
	int maxSort = lesson.getMaxSort(cid, useYn, siteId);

	lesson.item("id", newId);
	lesson.item("site_id", siteId);
	lesson.item("content_id", cid);
	lesson.item("lesson_nm", f.get("lesson_nm"));
	lesson.item("onoff_type", "N"); //온라인
	lesson.item("lesson_type", f.get("lesson_type"));
	lesson.item("author", f.get("author"));
	lesson.item("start_url", f.get("start_url"));
	lesson.item("mobile_a", f.get("mobile_url"));
	lesson.item("mobile_i", f.get("mobile_url"));
	lesson.item("short_url", f.get("short_url"));
	lesson.item("total_page", f.getInt("total_page"));
	lesson.item("total_time", f.getInt("total_time"));
	lesson.item("complete_time", f.getInt("complete_time"));
	lesson.item("content_width", f.getInt("content_width"));
	lesson.item("content_height", f.getInt("content_height"));
	lesson.item("description", f.get("description"));
	lesson.item("chat_yn", siteconfig.b("lesson_chat_yn") && "04".equals(f.get("lesson_type")) ? f.get("chat_yn") : "N"); //외부링크에서만 미니톡 채팅 사용
	lesson.item("ai_chat_yn", sysAIChat ? f.get("ai_chat_yn", "N") : "N");
	lesson.item("manager_id", userId);
	lesson.item("use_yn", useYn);
	lesson.item("sort", maxSort);
	lesson.item("reg_date", m.time("yyyyMMddHHmmss"));
	lesson.item("status", f.getInt("status"));

	/*
	if(null != f.getFileName("lesson_file")) {
		File file1 = f.saveFile("lesson_file");
		if(null != file1) lesson.item("lesson_file", f.getFileName("lesson_file"));
	}
	*/

	if(!lesson.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	//임시로 올려진 파일들의 게시물 아이디 지정
	file.updateTempFile(f.getInt("temp_id"), newId, "lesson");

	//쿠키-등록된강의
	m.setCookie("REGLESSON", "" + newId, 86400);

	//과정개설메뉴에서 신규강의 등록시
	if(courseId > 0) {

		DataSet cinfo2 = course.find("id = " + courseId);
		if(cinfo2.next()) {

			int maxChapter = courseLesson.getOneInt(
				"SELECT MAX(chapter) FROM " + courseLesson.table + " "
				+ " WHERE course_id = " + courseId + " "
			);

			courseLesson.item("course_id", courseId);
			courseLesson.item("site_id", siteId);
			courseLesson.item("start_day", 0);
			courseLesson.item("period", 0);
			courseLesson.item("start_date", cinfo2.s("study_sdate"));
			courseLesson.item("end_date", cinfo2.s("study_edate"));
			courseLesson.item("start_time", "000000");
			courseLesson.item("end_time", "235559");
			courseLesson.item("tutor_id", 0);
			courseLesson.item("progress_yn", "Y");
			courseLesson.item("status", 1);
			courseLesson.item("lesson_id", newId);
			courseLesson.item("chapter", ++maxChapter);
			courseLesson.item("lesson_hour", 1);
			if(courseLesson.insert()) {
				courseLesson.autoSort(courseId);
			}
		}
	}

	//채널 등록
	if(siteconfig.b("lesson_chat_yn") && "04".equals(f.get("lesson_type")) && "Y".equals(f.get("chat_yn"))) {
		DataSet cllist = courseLesson.query(
			"SELECT a.*, l.lesson_nm, c.course_nm "
			+ " FROM " + courseLesson.table + " a "
			+ " LEFT JOIN " + lesson.table + " l on a.lesson_id = l.id AND l.site_id = " + siteId
			+ " LEFT JOIN " + course.table + " c on a.course_id = c.id AND c.site_id = " + siteId
			+ " WHERE a.lesson_id = " + newId  + " AND a.site_id = " + siteId
		);

		DataSet wlist = webtv.find("lesson_id = ? AND site_id = ? AND status = ?", new Object[] {newId, siteId, 1});
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

	if("direct".equals(mode)) {
		m.js("try { parent.opener.document.forms['form1']['lesson_id'].value = '" + newId + "'; parent.opener.document.forms['form1']['lesson_nm'].value = '" + m.addSlashes(f.get("lesson_nm")) + "'; } catch(e) { } parent.window.close();");
		//m.p("parent.opener.document.forms['form1']['lesson_id'] = '" + newId + "'; parent.opener.document.forms['form1']['lesson_nm'] = '" + m.addSlashes(f.get("lesson_nm")) + "';");
	} else if("direct_audio".equals(mode)) {
		m.js("try { parent.opener.document.forms['form1']['audio_id'].value = '" + newId + "'; parent.opener.document.forms['form1']['audio_nm'].value = '" + m.addSlashes(f.get("lesson_nm")) + "'; } catch(e) { } parent.window.close();");
		//m.p("parent.opener.document.forms['form1']['lesson_id'] = '" + newId + "'; parent.opener.document.forms['form1']['lesson_nm'] = '" + m.addSlashes(f.get("lesson_nm")) + "';");
	} else {
		m.js("try { parent.opener.location.href = parent.opener.location.href; } catch(e) { } parent.window.close();");
	}
	return;
}

//출력
p.setLayout("pop");
p.setVar("p_title", "온라인강의관리");
p.setBody("content.lesson_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("wecandeo_block", -1 < request.getServerName().indexOf("malgn.co.kr") || "W".equals(siteinfo.s("ovp_vendor")));
p.setVar("catenoid_block", -1 < request.getServerName().indexOf("malgn.co.kr") || "C".equals(siteinfo.s("ovp_vendor")));
p.setVar("live_block", -1 < request.getServerName().indexOf("malgn.co.kr") || "Y".equals(SiteConfig.s("kollus_live_yn")));
p.setVar("doczoom_block", "Y".equals(SiteConfig.s("doczoom_yn")));
p.setVar("lesson_id", m.getRandInt(-2000000, 1990000));
p.setVar("aichat_block", sysAIChat);

p.setVar("SITE_CONFIG", siteconfig);
p.setVar("cid", cid);
p.setLoop("content_list", content.find(("C".equals(userKind) ? "manager_id = " + userId + " AND " : "") + "status != -1 AND site_id = " + siteId + "", "*", "content_nm ASC"));
p.setLoop("lesson_types", m.arr2loop(lesson.allLessonTypes));
p.setLoop("use_types", m.arr2loop(lesson.useTypes));
p.setLoop("chat_use_types", m.arr2loop(lesson.chatUseTypes));
p.setLoop("status_list", m.arr2loop(lesson.statusList));
p.display();

%>