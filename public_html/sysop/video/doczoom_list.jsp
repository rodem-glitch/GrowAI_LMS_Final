<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!"Y".equals(SiteConfig.s("doczoom_yn"))) { m.jsError("문서(닥줌) 서비스를 이용하고 있지 않습니다."); return; }

//객체
LessonDao lesson = new LessonDao();
ContentDao content = new ContentDao();
DoczoomDao doczoom = new DoczoomDao();

//등록
if(m.isPost() && f.validate()) {
	//변수
	/*
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
		lesson.item("lesson_nm", (String)temp.get("title"));
		lesson.item("onoff_type", "N"); //온라인
		lesson.item("lesson_type", "05"); //KOLLUS
		lesson.item("author", "");
		lesson.item("start_url", idx[i]);
		lesson.item("mobile_a", idx[i]);
		lesson.item("mobile_i", idx[i]);
		lesson.item("total_page", 0);
		lesson.item("total_time", m.parseInt((String)temp.get("total_time")));
		lesson.item("complete_time", 0);
		lesson.item("content_width", m.parseInt((String)temp.get("content_width")));
		lesson.item("content_height", m.parseInt((String)temp.get("content_height")));
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
	*/
}


//폼체크
f.addElement("s_keyword", null, null);
int pg = m.ri("page") > 0 ? m.ri("page") : 1;

//컨텐츠 목록을 가져올 때 지정할 조건값들. Integer 변수에 null을 지정하면 해당 조건은 무시됩니다.
String userID = "malgn_" + siteinfo.s("ftp_id");
String title = m.rs("s_keyword", null);
String tag = null;
String categoryID = null;

//doczoom.setDebug(out);
int totalNum = doczoom.getContentCount(userID, title, tag, categoryID);
int pageSize = 100;  //한 페이지당 항목 개수

DataSet list = doczoom.getPaginatedContentInfoListWithFilters(pageSize, pg, 1, 1, userID, title, tag, categoryID);
while(list.next()) {
	long t = Long.parseLong(list.s("RegistrationDate").replace("/Date(", "").replace(")/", ""));
	list.put("RegistrationDate", m.time("yyyy.MM.dd", new Date(t)));
	list.put("DocZoomSize", m.getFileSize(list.i("DocZoomSize")));
}

//페이징
Pager pager = new Pager(request);
pager.setTotalNum(totalNum);
pager.setPageNum(pg);

//출력
p.setLayout("sysop");
p.setBody("video.doczoom_list");
p.setVar("p_title", "문서 콘텐츠 관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());
p.setVar("list_total", totalNum);
p.setVar("pagebar", pager.getPager());
p.setVar("doczoom_id", siteinfo.s("ftp_id"));
p.setVar("doczoom_pw", m.urlencode(Base64Coder.encode(siteinfo.s("ftp_pw"))));
p.setLoop("list", list);
p.setLoop("content_list", content.find("status != -1 AND site_id IN (0, " + siteId + ")", "id, content_nm"));
p.display();

%>