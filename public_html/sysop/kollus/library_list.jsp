<%@ page contentType="text/html; charset=utf-8" %><%@ page import="malgnsoft.json.*" %><%@ include file="init.jsp" %><%

//객체
KollusDao kollus = new KollusDao(siteId);
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
String categoryKey = null;
DataSet categories = kollus.getCategories();
if("user".equals(siteinfo.s("kollus_channel"))) {
	while(categories.next()) {
		if(categories.s("name").equals(loginId)) {
			categoryKey = categories.s("key");
			break;
		}
	}
	if(categoryKey == null) {
		kollus.addCategory(loginId);
		if("Y".equals(m.rs("reload"))) {
			m.jsError("카테고리 생성에 실패했습니다. 관리자에게 문의바랍니다.");
		} else {
			m.redirect("library_list.jsp?reload=Y");
		}
		return;
	}
} else {
	categories.first();
	categories.next();
	categoryKey = categories.s("key");
}

String category = m.rs("s_category", categoryKey);

//폼체크
f.addElement("s_category", category, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
int pg = m.ri("page") > 0 ? m.ri("page") : 1;

//목록
//kollus.setDebug(out);
DataSet list = kollus.getCategoryContents(category, m.rs("s_keyword"), pg, 10);
int totalNum = kollus.getTotalNum();
int i = 1;
while(list.next()) {
	list.put("use_encryption_conv", "1".equals(list.s("use_encryption")) ? "Y" : "N");
	list.put("encrypt_block", "1".equals(list.s("use_encryption")));
	list.put("__ord", i++);
	list.put("ROW_CLASS", i % 2 == 1 ? "odd" : "even");


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
p.setLayout(ch);
p.setBody("kollus.library_list");
p.setVar("p_title", "동영상 관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("list_total", totalNum);
p.setLoop("list", list);
p.setLoop("categories", categories);
p.setVar("pagebar", pager.getPager());

p.setLoop("content_list", content.find("status != -1 AND site_id IN (0, " + siteId + ")", "id, content_nm"));
p.display();

%>