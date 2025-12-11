<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!(Menu.accessible(123, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
WebtvDao webtv = new WebtvDao();
LessonDao lesson = new LessonDao();
WebtvTargetDao webtvTarget = new WebtvTargetDao();
LmCategoryDao category = new LmCategoryDao("webtv");
FileDao file = new FileDao();
MCal mcal = new MCal();

//목록-카테고리
DataSet categories = category.getList(siteId);
if(1 > categories.size()) { m.jsError("등록된 방송카테고리가 없습니다.\\n방송을 등록하시려면 먼저 방송카테고리를 등록해주세요."); return; }

//폼체크
f.addElement("category_id", null, "hname:'카테고리', required:'Y'");
f.addElement("webtv_nm", null, "hname:'방송제목', required:'Y'");
f.addElement("webtv_file", null, "hname:'메인이미지', allow:'jpg|jpeg|gif|png'");
f.addElement("lesson_id", null, "hname:'강의'");
f.addElement("lesson_nm", null, "hname:'강의명'");
f.addElement("audio_id", null, "hname:'오디오강의'");
f.addElement("audio_nm", null, "hname:'오디오강의명'");
f.addElement("grade", "H1", "hname:'학년', required:'Y'");
f.addElement("term", "1T", "hname:'학기', required:'Y'");
f.addElement("subject", "K", "hname:'과목', required:'Y'");
f.addElement("link_yn", null, "hname:'링크사용여부'");
f.addElement("link", null, "hname:'링크'");
f.addElement("recomm_yn", null, "hname:'추천방송'");
f.addElement("subtitle", null, "hname:'부제목'");
f.addElement("content", null, "hname:'방송내용', allowhtml:'Y'");
f.addElement("keyword", null, "hname:'키워드', maxlength:'500'");
f.addElement("length_min", "0", "hname:'방송길이(분)', required:'Y', option:'number', min:'0', max:'999'");
f.addElement("length_sec", "0", "hname:'방송길이(초)', required:'Y', option:'number', min:'0', max:'59'");
f.addElement("open_date", m.time("yyyy-MM-dd"), "hname:'방송일', required:'Y'");
f.addElement("open_hour", "00", "hname:'방송시간(시)', required:'Y'");
f.addElement("open_min", "00", "hname:'방송시간(분)', required:'Y'");
f.addElement("end_yn", "N", "hname:'노출만료일 사용여부', required:'Y'");
f.addElement("end_date", null, "hname:'노출만료일'");
f.addElement("end_hour", "00", "hname:'노출만료시간(시)'");
f.addElement("end_min", "00", "hname:'노출만료시간(분)'");
f.addElement("target_yn", "N", "hname:'시청대상 사용여부', required:'Y'");
f.addElement("comment_yn", "N", "hname:'댓글사용여부', required:'Y'");
f.addElement("display_yn", "Y", "hname:'노출여부', required:'Y'");
f.addElement("status", 1, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	String content = f.get("content");
	int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(-1 < content.indexOf("<img") && -1 < content.indexOf("data:image/") && -1 < content.indexOf("base64")) {
		m.jsAlert("이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}
	if(60000 < bytes) { m.jsAlert("내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes + "바이트)"); return; }

	int newId = webtv.getSequence();

	webtv.item("id", newId);
	webtv.item("site_id", siteId);
	webtv.item("category_id", f.getInt("category_id"));
	webtv.item("lesson_id", f.getInt("lesson_id"));
	webtv.item("audio_id", f.getInt("audio_id"));
	webtv.item("webtv_nm", f.get("webtv_nm"));
	webtv.item("link_yn", f.get("link_yn", "N"));
	webtv.item("link", f.get("link"));
	webtv.item("grade", f.get("grade", "H1"));
	webtv.item("term", f.get("term", "1T"));
	webtv.item("subject", f.get("subject", "K"));
	webtv.item("subtitle", f.get("subtitle"));
	webtv.item("content", content);
	webtv.item("keywords", m.replace(f.get("keywords"), ",", "|"));

	webtv.item("length_min", f.getInt("length_min"));
	webtv.item("length_sec", f.getInt("length_sec"));

	webtv.item("open_date", m.time("yyyyMMdd", f.get("open_date")) + f.get("open_hour") + f.get("open_min") + "00");
	webtv.item("end_date", "Y".equals(f.get("end_yn", "N")) ? m.time("yyyyMMdd", f.get("end_date")) + f.get("end_hour") + f.get("end_min") + "00" : "");
	webtv.item("end_yn", f.get("end_yn", "N"));

	webtv.item("recomm_yn", f.get("recomm_yn", "N"));
	webtv.item("comment_yn", f.get("comment_yn", "Y"));
	webtv.item("target_yn", f.get("target_yn", "N"));
	webtv.item("display_yn", "Y");
	webtv.item("reg_date", m.time("yyyyMMddHHmmss"));
	webtv.item("status", f.get("status"));

	if(null != f.getFileName("webtv_file")) {
		File f1 = f.saveFile("webtv_file");
		if(f1 != null) {
			webtv.item("webtv_file", f.getFileName("webtv_file"));

			//리사이즈
			try {
				String imgPath = dataDir + "/file/" + f1.getName();
				String cmd = "convert -resize 1200x " + imgPath + " " + imgPath;
				Runtime.getRuntime().exec(cmd);
			}catch(RuntimeException re) {
				m.errorLog("RuntimeException : " + re.getMessage(), re);
				return;
			}
			catch(Exception e) {
				m.errorLog("Exception : " + e.getMessage(), e);
				return;
			}
		}
	}

	//임시로 올려진 파일들의 게시물 아이디 지정
	file.updateTempFile(f.getInt("temp_id"), newId, "webtv");

	//갱신
	webtv.updateFileCount(newId);

	if(!webtv.insert()) { m.jsAlert("등록하는 중 오류가 발생하였습니다."); return; }

	//시청대상
	if(null != f.getArr("group_id")) {
		webtvTarget.item("webtv_id", newId);
		for(int i = 0; i < f.getArr("group_id").length; i++) {
			webtvTarget.item("group_id", f.getArr("group_id")[i]);
			webtvTarget.item("site_id", siteId);
			if(!webtvTarget.insert()) { }
		}
	}

	DataSet lessonInfo = lesson.find(" id = ? AND site_id = ? AND status = ?", new Object[]{ f.getInt("lesson_id"), siteId, 1});
	if(lessonInfo.next() && "Y".equals(lessonInfo.s("chat_yn"))) {
		String categoryNm = siteinfo.s("site_nm");
		String channelId = lesson.getChannelId(siteinfo.s("ftp_id"), siteId, newId, lessonInfo.i("id"), "w");
		//String title = wlist.s("webtv_nm") + " - " + wlist.s("lesson_nm");
		lesson.insertChannel(channelId, categoryNm, "채팅방");
	}

	//이동
	m.jsReplace("webtv_list.jsp?" + m.qs(), "parent");
	return;
}

//출력
p.setBody("webtv.webtv_insert");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setLoop("status_list", m.arr2loop(webtv.statusList));
p.setLoop("comment_list", m.arr2loop(webtv.commentList));
p.setLoop("display_list", m.arr2loop(webtv.displayList));
p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes());
p.setLoop("categories", categories);

p.setLoop("grades", m.arr2loop(webtv.grades));
p.setLoop("terms", m.arr2loop(webtv.terms));
p.setLoop("subjects", m.arr2loop(webtv.subjects));


p.setVar("id", m.getRandInt(-2000000, 1990000));

p.display();

%>