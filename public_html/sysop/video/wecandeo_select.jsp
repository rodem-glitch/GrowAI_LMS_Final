<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

int pageno = m.ri("page") == 0 ? 1 : m.ri("page");

//객체
String videoKey = siteinfo.s("video_key");
WecandeoDao wecandeo = new WecandeoDao(videoKey);

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
}

//페이징
Pager pg = new Pager(request);
pg.setTotalNum(wecandeo.getTotalNum());
pg.setListNum(20);
pg.setPageNum(pageno);

//출력
p.setLayout("pop");
p.setBody("video.wecandeo_select");
p.setVar("p_title", "동영상 선택");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("access_key"));
p.setVar("form_script", f.getScript());
p.setVar("package_block", "".equals(siteinfo.s("video_pkg")));
p.setLoop("packages", packages);
p.setLoop("list", list);
p.setVar("list_total", m.nf(wecandeo.getTotalNum()));
p.setVar("pagebar", pg.getPager());

p.setVar("package_id", packageId);
p.display();

%>