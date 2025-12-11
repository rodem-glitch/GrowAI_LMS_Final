<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.net.URL,javax.net.ssl.*" %><%@ page import="malgnsoft.json.*" %><%@ page import="java.util.HashMap" %><%@ include file="init.jsp" %><%

//객체
KollusDao kollus = new KollusDao(siteId);
LessonDao lesson = new LessonDao();
ContentDao content = new ContentDao();
//kollus.d(out);
if(2 == m.ri("version")) kollus.setApiVersion("api-vod");

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
}

//목록-채널
String channelKey = "";
DataSet channels = kollus.getChannels();
if(null == channels || 1 > channels.size()) {
	m.jsError("채널을 불러올 수 없습니다. 관리자에게 문의바랍니다.");
	return;
}

if("user".equals(siteinfo.s("kollus_channel")) && !superBlock) {
	channelKey = kollus.getChannelKey(channels, loginId);
} else {
	channelKey = kollus.getChannelKey(channels, "폴리텍대학");
	/*
	while(channels.next()) {
		if("비공개".equals(channels.s("name"))) channelKey = channels.s("key");
	}
	*/
	channelKey = m.rs("s_channel", channelKey);

	//계정에 사용중인 채널이 여러개 있을 때
	/*if(channels.size() > 1 && "".equals(channelKey)) {
		if(!"".equals(siteinfo.s("kollus_channel"))) {
			channelKey = siteinfo.s("kollus_channel");
		} else {
			channels.first();
			channels.next();
			channelKey = channels.s("key");
		}
	}*/
	//채널키를 못 찾은 경우 사이트설정이 되어있는 채널키를 사용하거나 첫번째 채널키를 사용
	if("".equals(channelKey)) {
		if(!"".equals(siteinfo.s("kollus_channel"))) {
			channelKey = siteinfo.s("kollus_channel");
		} else {
			channels.first();
			channels.next();
			channelKey = channels.s("key");
		}
	}
}

if("".equals(channelKey)) {
	m.jsError("유효한 채널이 존재하지 않습니다. 관리자에게 문의바랍니다.");
	return;
}

//목록-카테고리
String categoryKey = "";
DataSet categories = kollus.getCategories();
if(null == categories || 1 > categories.size()) {
	m.jsError("카테고리를 불러올 수 없습니다. 관리자에게 문의바랍니다.");
	return;
}
HashMap<String, String> categoryMap = new HashMap<String, String>();
while(categories.next()) {
	categoryMap.put(categories.s("key"), categories.s("name"));
}
categories.first();

if("user".equals(siteinfo.s("kollus_channel")) && !superBlock) {
	categoryKey = kollus.getCategoryKey(categories, loginId);
} else {
	categoryKey = m.rs("s_category");
}
kollus.setCategoryKey(categoryKey);

//폼체크
f.addElement("s_channel", channelKey, null);
f.addElement("s_category", categoryKey, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
int pg = m.ri("page") > 0 ? m.ri("page") : 1;
//m.p(m.rs("s_category"));

//목록
DataSet list = kollus.getContents(channelKey, m.rs("s_keyword"), pg, 20);
int totalNum = kollus.getTotalNum();
int i = 1;
//m.p(list);
while(list.next()) {
	//m.p(list.getRow());
	list.put("__ord", i++);
	list.put("ROW_CLASS", i % 2 == 1 ? "odd" : "even");

	//api
	list.put("category_nm", categoryMap.containsKey(list.s("category_key")) ? categoryMap.get(list.s("category_key")) : "-");
	list.put("use_encryption_conv", "1".equals(list.s("use_encryption")) ? "Y" : "N");
	list.put("encrypt_block", "1".equals(list.s("use_encryption")));

	if(!"".equals(list.s("duration")) && -1 < list.s("duration").indexOf(":")) {
		String[] duration = m.split(":", list.s("duration"));

		list.put("total_time", m.parseInt(duration[0]) * 60 + m.parseInt(duration[1]));
	} else {
		list.put("duration", "-");
		list.put("total_time", "0");
	}

	list.put("content_width", "0");
	list.put("content_height", "0");
	if(!"".equals(list.s("transcoding_files"))) {
		DataSet tfinfo = Json.decode(list.s("transcoding_files"));

		while(tfinfo.next()) {
			if(-1 < tfinfo.s("media_profile_group_key").toLowerCase().indexOf("pc")) {
				DataSet minfo = Json.decode(tfinfo.s("media_information"));
				while(minfo.next()) {
					DataSet vinfo = Json.decode(minfo.s("video"));
					if(vinfo.next() && !"".equals(vinfo.s("video_screen_size")) && -1 < vinfo.s("video_screen_size").indexOf("x")) {
						String[] size = m.split("x", vinfo.s("video_screen_size"));
						list.put("content_width", size[0]);
						list.put("content_height", size[1]);
					}
				}
			}
		}
	}
}

//페이징
Pager pager = new Pager(request);
pager.setTotalNum(totalNum);
pager.setPageNum(pg);

//출력
p.setLayout("sysop");
p.setBody("video.kollus_list");
p.setVar("p_title", "동영상 관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());
p.setVar("list_total", totalNum);
p.setVar("pagebar", pager.getPager());
p.setVar("category_block", !"user".equals(siteinfo.s("kollus_channel")) || superBlock);
p.setVar("channel_block", !"user".equals(siteinfo.s("kollus_channel")) || superBlock);

p.setLoop("list", list);
p.setLoop("categories", categories);
//m.p(categories);
p.setLoop("channels", channels);

p.setLoop("content_list", content.find("status != -1 AND site_id IN (0, " + siteId + ")", "id, content_nm"));
p.display();

%>