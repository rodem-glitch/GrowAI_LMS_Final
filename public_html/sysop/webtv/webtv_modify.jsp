<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!(Menu.accessible(123, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

//객체
WebtvDao webtv = new WebtvDao();
WebtvTargetDao webtvTarget = new WebtvTargetDao();
GroupDao group = new GroupDao();
LessonDao lesson = new LessonDao();
LmCategoryDao category = new LmCategoryDao("webtv");
MCal mcal = new MCal();

//정보
DataSet info = webtv.query(
	" SELECT a.*, l.lesson_nm, m.lesson_nm audio_nm "
	+ " FROM " + webtv.table + " a "
	+ " LEFT JOIN " + lesson.table + " l ON a.lesson_id = l.id AND l.site_id = " + siteId
	+ " LEFT JOIN " + lesson.table + " m ON a.audio_id = m.id AND m.site_id = " + siteId
	+ " WHERE a.id = " + id + " AND a.status != -1 AND a.site_id = " + siteId
);
if(!info.next()) { m.jsAlert("해당 정보가 없습니다."); return; }
info.put("open_date_conv", m.time("yyyy-MM-dd", info.s("open_date")));
info.put("open_hour", m.time("HH", info.s("open_date")));
info.put("open_min", m.time("mm", info.s("open_date")));
info.put("end_date_conv", m.time("yyyy-MM-dd", info.s("end_date")));
info.put("end_hour", m.time("HH", info.s("end_date")));
info.put("end_min", m.time("mm", info.s("end_date")));

//파일삭제
if("fdel".equals(m.rs("mode"))) {
	//제한
	if(!"".equals(info.s("webtv_file"))) {
		webtv.item("webtv_file", "");
		if(!webtv.update("id = " + id)) { }
		m.delFileRoot(m.getUploadPath(info.s("webtv_file")));
	}
	return;
}

//폼체크
f.addElement("category_id", info.s("category_id"), "hname:'카테고리', required:'Y'");
f.addElement("webtv_nm", info.s("webtv_nm"), "hname:'방송제목', required:'Y'");
f.addElement("webtv_file", null, "hname:'메인이미지', allow:'jpg|jpeg|gif|png'");
f.addElement("lesson_id", info.s("lesson_id"), "hname:'강의'");
f.addElement("lesson_nm", info.s("lesson_nm"), "hname:'강의명'");
f.addElement("audio_id", info.s("audio_id"), "hname:'오디오강의'");
f.addElement("audio_nm", info.s("audio_nm"), "hname:'오디오강의명'");
f.addElement("link_yn", info.s("link_yn"), "hname:'링크사용여부'");
f.addElement("link", info.s("link"), "hname:'링크'");

f.addElement("grade", info.s("grade"), "hname:'학년', required:'Y'");
f.addElement("term", info.s("term"), "hname:'학기', required:'Y'");
f.addElement("subject", info.s("subject"), "hname:'과목', required:'Y'");

f.addElement("recomm_yn", info.s("recomm_yn"), "hname:'추천방송'");
f.addElement("subtitle", null, "hname:'부제목'");
f.addElement("content", null, "hname:'방송내용'");
f.addElement("keywords", m.replace(info.s("keywords"), "|", ","), "hname:'키워드', maxlength:'500'");
f.addElement("length_min", info.i("length_min"), "hname:'방송길이(분)', required:'Y', option:'number', min:'0', max:'999'");
f.addElement("length_sec", info.i("length_sec"), "hname:'방송길이(초)', required:'Y', option:'number', min:'0', max:'59'");
f.addElement("open_date", info.s("open_date_conv"), "hname:'방송일', required:'Y'");
f.addElement("open_hour", info.s("open_hour"), "hname:'방송시간(시)', required:'Y'");
f.addElement("open_min", info.s("open_min"), "hname:'방송시간(분)', required:'Y'");
f.addElement("end_yn", info.s("end_yn"), "hname:'노출만료일 사용여부', required:'Y'");
f.addElement("end_date", info.s("end_date_conv"), "hname:'노출만료일'");
f.addElement("end_hour", info.s("end_hour"), "hname:'노출만료시간(시)'");
f.addElement("end_min", info.s("end_min"), "hname:'노출만료시간(분)'");
f.addElement("target_yn", info.s("target_yn"), "hname:'시청대상 사용여부', required:'Y'");
f.addElement("comment_yn", info.s("comment_yn"), "hname:'댓글사용여부', required:'Y'");
f.addElement("display_yn", info.s("display_yn"), "hname:'노출여부', required:'Y'");
f.addElement("status", info.s("status"), "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	String content = f.get("content");
	int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(-1 < content.indexOf("<img") && -1 < content.indexOf("data:image/") && -1 < content.indexOf("base64")) {
		m.jsAlert("이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}
	if(60000 < bytes) { m.jsAlert("내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes + "바이트)"); return; }

	webtv.item("category_id", f.getInt("category_id"));
	webtv.item("lesson_id", f.getInt("lesson_id"));
	webtv.item("audio_id", f.getInt("audio_id"));
	webtv.item("webtv_nm", f.get("webtv_nm"));
	webtv.item("link_yn", f.get("link_yn", "N"));
	webtv.item("link", f.get("link"));

	webtv.item("grade", f.get("grade"));
	webtv.item("term", f.get("term"));
	webtv.item("subject", f.get("subject"));

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
	webtv.item("display_yn", f.get("display_yn", "N"));
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
			}
			catch(RuntimeException re) {
				m.errorLog("RuntimeException : " + re.getMessage(), re);
				return;
			}
			catch(Exception e) {
				m.errorLog("Exception : " + e.getMessage(), e);
				return;
			}
		}
	}

	//갱신
	webtv.updateFileCount(id);

	if(!webtv.update("id = " + id)) { m.jsAlert("수정하는 중 오류가 발생하였습니다."); return; }

	//시청대상
	if(-1 != webtvTarget.execute("DELETE FROM " + webtvTarget.table + " WHERE webtv_id = " + id + "")) {
		if(null != f.getArr("group_id")) {
			webtvTarget.item("webtv_id", id);
			for(int i = 0; i < f.getArr("group_id").length; i++) {
				webtvTarget.item("group_id", f.getArr("group_id")[i]);
				webtvTarget.item("site_id", siteId);
				if(!webtvTarget.insert()) { }
			}
		}
	}

	DataSet lessonInfo = lesson.find(" id = ? AND site_id = ? AND status = ?", new Object[]{ f.getInt("lesson_id"), siteId, 1});
	if(lessonInfo.next() && "Y".equals(lessonInfo.s("chat_yn"))) {
		String categoryNm = siteinfo.s("site_nm");
		String channelId = lesson.getChannelId(siteinfo.s("ftp_id"), siteId, id, lessonInfo.i("id"), "w");
		//String title = wlist.s("webtv_nm") + " - " + wlist.s("lesson_nm");
		lesson.insertChannel(channelId, categoryNm, "채팅방");
	}

	//이동
	m.jsReplace("webtv_list.jsp?" + m.qs("id"), "parent");
	return;
}

//포맷팅
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("webtv_file_conv", m.encode(info.s("webtv_file")));
info.put("webtv_file_url", m.getUploadUrl(info.s("webtv_file")));
info.put("webtv_file_ek", m.encrypt(info.s("webtv_file") + m.time("yyyyMMdd")));

//목록-대상자
DataSet targets = webtvTarget.query(
	"SELECT a.*, g.group_nm "
	+ " FROM " + webtvTarget.table + " a "
	+ " INNER JOIN " + group.table + " g ON a.group_id = g.id AND g.site_id = " + siteId + " "
	+ " WHERE a.webtv_id = " + id + ""
);

//출력
p.setBody("webtv.webtv_insert");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setVar(info);
p.setVar("modify", true);
p.setLoop("targets", targets);

p.setLoop("status_list", m.arr2loop(webtv.statusList));
p.setLoop("comment_list", m.arr2loop(webtv.commentList));
p.setLoop("display_list", m.arr2loop(webtv.displayList));
p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes());
p.setLoop("categories", category.getList(siteId));

p.setLoop("grades", m.arr2loop(webtv.grades));
p.setLoop("terms", m.arr2loop(webtv.terms));
p.setLoop("subjects", m.arr2loop(webtv.subjects));

p.setVar("tab_modify", "current");
p.setVar("wid", id);
p.display();

%>