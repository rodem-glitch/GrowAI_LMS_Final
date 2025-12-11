<%@ page import="java.util.Arrays" %>
<%@ page import="malgnsoft.util.Json" %>
<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

String ch = "sysop";

//레이아웃파일
List<String> layoutCodes = Arrays.asList(new String[] {
	"top", "footer", "header", "left", "template_layout", "layout_main", "layout_board", "layout_book", "layout_classroom"
	, "layout_course", "layout_intro", "layout_member", "layout_mypage", "layout_order", "layout_schedule", "layout_search"
	, "layout_tutor", "layout_webtv", "top_b2b", "layout_b2b", "layout_blank", "layout_mobile", "layout_mail"
});
String[] layoutArr = {
	"top=>PC 상단 영역", "footer=>PC 하단 영역", "header=>PC 공통 스크립트 영역", "left=>PC 소메뉴 영역"
	, "template_layout=>PC 레이아웃 기본 템플릿", "layout_main=>PC 레이아웃 (메인)", "layout_board=>PC 레이아웃 (고객센터)"
	, "layout_book=>PC 레이아웃 (온라인서점)", "layout_classroom=>PC 레이아웃 (강의실)", "layout_course=>PC 레이아웃 (수강신청)"
	, "layout_intro=>PC 레이아웃 (소개)", "layout_member=>PC 레이아웃 (회원서비스)", "layout_mypage=>PC 레이아웃 (마이페이지)"
	, "layout_order=>PC 레이아웃 (주문)", "layout_schedule=>PC 레이아웃 (교육일정)", "layout_search=>PC 레이아웃 (검색)"
	, "layout_tutor=>PC 레이아웃 (강사소개)", "layout_webtv=>PC 레이아웃 (인터넷방송)", "top_b2b=>PC B2B 상단 영역"
	, "layout_b2b=>PC B2B 레이아웃"
	, "layout_blank=>모듈 전체 상하단 영역", "layout_mobile=>모바일 전체 상하단 영역", "layout_mail=>발신메일 레이아웃"
};
/*
File layoutDir = new File(siteinfo.s("doc_root") + "/html/layout");
DataSet layouts = m.arr2loop(layoutArr);
layouts.last();
if(layoutDir.exists()) {
	File[] files = layoutDir.listFiles();
	for(int i = 0; i < files.length; i++) {
		String filename = files[i].getName();
		if(-1 < filename.indexOf(".")) {
			String filecode = filename.substring(0, filename.lastIndexOf("."));
			if(!layoutCodes.contains(filecode)) {
				layouts.addRow();
				layouts.put("id", filecode);
				layouts.put("name", filecode.startsWith("layout_") ? "기타 레이아웃 (" + m.replace(filecode, "layout_", "") + ")" : filename);
			}
		}
	}
}
layouts.first();
*/
String apiUrl = "http://" + (!isDevServer ? "221.143.42.214" : "lms.malgn.co.kr") + "/api/file.jsp";
Json j = new Json(apiUrl + "?mode=files&uid=" + siteinfo.s("ftp_id") + "&folder=layout");
DataSet layouts = m.arr2loop(layoutArr);
DataSet layoutsTemp = j.getDataSet("//files");
layouts.last();
while(layoutsTemp.next()) {
	if(!layoutCodes.contains(layoutsTemp.s("pname"))) {
		layouts.addRow();
		layouts.put("id", layoutsTemp.s("pname"));
		layouts.put("name", layoutsTemp.s("pname").startsWith("layout_") ? "기타 레이아웃 (" + m.replace(layoutsTemp.s("pname"), "layout_", "") + ")" : layoutsTemp.s("name"));
	}
}
layouts.first();

//CSS파일
List<String> cssCodes = Arrays.asList(new String[] { "custom", "mobile" });
String[] cssArr = { "custom=>PC CSS", "mobile=>모바일 CSS" };

//폼입력
String mode = !"".equals(m.rs("mode")) ? m.rs("mode") : "layout";

%>