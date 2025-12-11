<%@ page contentType="text/html; charset=utf-8" %><%@ page import="org.json.*" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(69, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

int pageno = m.ri("page") == 0 ? 1 : m.ri("page");

//객체
String videoKey = siteinfo.s("video_key");
WecandeoDao wecandeo = new WecandeoDao(videoKey);
LessonDao lesson = new LessonDao();
ContentDao content = new ContentDao();

//등록
if(m.isPost() && f.validate()) {
	//변수
	String[] idx = f.getArr("idx");
	int cid = f.getInt("content_id");
	int success = 0;
	
	//제한
	if(0 == cid) { m.jsAlert("콘텐츠는 반드시 지정해야 합니다."); return; }
	if(null == idx) { m.jsAlert("동영상은 반드시 선택해야 합니다."); return; }

	//등록
	for(int i = 0; i < idx.length; i++) {
		if(0 < lesson.findCount("content_id = " + cid + " AND start_url = '" + idx[i] + "' AND site_id = " + siteId + " AND status != -1")) continue;
		
		Hashtable temp = f.getMap(idx[i] + "_");
		lesson.item("site_id", siteId);
		lesson.item("content_id", cid);
		lesson.item("lesson_nm", temp.get("title"));
		lesson.item("onoff_type", "N"); //온라인
		lesson.item("lesson_type", "01"); //WECANDEO
		lesson.item("author", "");
		lesson.item("start_url", "http://api.wecandeo.com/video.mp4?k=" + idx[i]);
		lesson.item("mobile_a", "http://api.wecandeo.com/video.mp4?k=" + idx[i]);
		lesson.item("mobile_i", "http://api.wecandeo.com/video.mp4?k=" + idx[i]);
		lesson.item("total_page", 0);
		lesson.item("total_time", temp.get("total_time"));
		lesson.item("complete_time", 0);
		lesson.item("content_width", temp.get("content_width"));
		lesson.item("content_height", temp.get("content_height"));
		lesson.item("description", "");
		lesson.item("manager_id", userId);
		lesson.item("use_yn", "Y");
		lesson.item("sort", lesson.getMaxSort(cid, "Y", siteId));
		lesson.item("reg_date", m.time("yyyyMMddHHmmss"));
		lesson.item("status", 1);
		if(lesson.insert()) success++;
	}
	
	//이동
	m.js(
		"if(confirm('총 " + idx.length + "건 중 " + success + "건을 등록했습니다.\\n\\n강의 순서와 인정시간은 별도로 지정하셔야 합니다.\\n강의목차로 이동하시겠습니까?')) {"
			+ "parent.location.href = '../content/lesson_list.jsp?cid=" + cid + "';"
		+ "} else {"
			+ "parent.location.reload();"
		+ "}"
	);
	return;
}

//목록-폴더
String packageId = siteinfo.s("video_pkg");
DataSet packages = wecandeo.getPackages();
int total = 0;
if("".equals(packageId) || superBlock) {
	packageId = wecandeo.getPackageId(packages, null);
} else if("user".equals(packageId)) {
	packageId = wecandeo.getPackageId(packages, loginId);
}

if("".equals(packageId)) {
	m.jsError("배포 패키지를 찾을 수 없습니다. 관리자에게 문의해주세요."); return;
}

//폼입력
packageId = m.rs("package_id", packageId);

//폼체크
f.addElement("package_id", packageId, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
wecandeo.setPage(f.getInt("page", 1));
wecandeo.setPage(pageno);
DataSet list = wecandeo.getVideos(packageId, f.get("s_keyword"));
while(list.next()) {
	list.put("reg_date_conv", list.s("cdate").substring(0,16));
	list.put("duration_conv", wecandeo.getDurationString(list.i("duration")));
	int durationMin = (int)(list.i("duration") / 1000 / 60);
	list.put("duration_min", durationMin <= 0 ? 1 : durationMin);
	list.put("status_conv", "Y".equals(list.s("encoding_success")) ? "정상" : "인코딩중");
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "동영상관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "id=>고유값", "title=>제목", "author=>저작자", "copyright=>저작권", "series=>시리즈", "content=>통계", "tag=>태그", "duration_conv=>재생시간", "reg_date_conv=>등록일" }, "동영상관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//페이징
Pager pg = new Pager(request);
pg.setTotalNum(wecandeo.getTotalNum());
pg.setListNum(20);
pg.setPageNum(pageno);

//출력
p.setLayout("sysop");
p.setBody("video.wecandeo_list");
p.setVar("p_title", "동영상 관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("access_key"));
p.setVar("form_script", f.getScript());
p.setVar("package_block", "".equals(siteinfo.s("video_pkg")));
p.setLoop("packages", packages);
p.setLoop("list", list);
p.setVar("list_total", m.nf(wecandeo.getTotalNum()));
p.setVar("pagebar", pg.getPager());
p.setVar("package_id", packageId);
p.setLoop("content_list", content.find("status != -1 AND site_id IN (0, " + siteId + ")", "id, content_nm"));
p.display();

%>