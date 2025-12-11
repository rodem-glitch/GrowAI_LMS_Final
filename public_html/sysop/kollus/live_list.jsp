<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init_live.jsp" %><%

//접근권한
if(!Menu.accessible(135, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//폼입력
int pageNum = m.ri("page");

//폼체크
f.addElement("s_keyword", null, null);

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

//처리
Http http = new Http("https://api-live-kr.kollus.com/api/v1/live/service-accounts/malgn/channels?order=id_desc&per_page=20&live_status=all&shared_status=all&trashed=0&page=" + (pageNum > 0 ? pageNum : 1) + (!"".equals(m.rs("s_keyword")) ? "&keyword=" + m.rs("s_keyword") : ""));
//http.setDebug(out);
http.setHeader("Authorization", "Bearer " + SiteConfig.s("kollus_live_access_token"));
String result = http.send("GET");
if("".equals(result)) { m.jsAlert("해당 정보가 없습니다."); return; }

//목록
Json j = new Json(result);
DataSet list = j.getDataSet("//data");
DataSet meta = j.getDataSet("//meta");
if(!meta.next()) { m.jsAlert("정보를 불러오는 중 오류가 발생했습니다."); return; }

//out.println(list.toString());
//포맷팅
while(list.next()) {
    list.put("latest_date_conv", "");
    DataSet lbinfo = Json.decode(list.s("latest_broadcast"));
    while(lbinfo.next()) {
        String temp = "";
        if(!"".equals(lbinfo.s("ended_at"))) temp = lbinfo.s("ended_at");
        else if(!"".equals(lbinfo.s("paused_at"))) temp = lbinfo.s("paused_at");
        else if(!"".equals(lbinfo.s("started_at"))) temp = lbinfo.s("started_at");

        OffsetDateTime latestDate = OffsetDateTime.parse(temp);
        list.put("latest_date_conv", m.time("yyyy-MM-dd HH:mm:ss", new Date().from(latestDate.toInstant())));
    }

    OffsetDateTime regDate = OffsetDateTime.parse(list.s("created_at"));
    list.put("reg_date_conv", m.time("yyyy-MM-dd HH:mm:ss", new Date().from(regDate.toInstant())));
}

//페이징
Pager pager = new Pager(request);
pager.setTotalNum(meta.i("last_page"));
pager.setPageNum(meta.i("current_page"));

//출력
p.setLayout("sysop");
p.setBody("kollus.live_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", meta.i("total"));
p.setVar("pagebar", pager.getPager());

p.setLoop("content_list", content.find("status != -1 AND site_id IN (0, " + siteId + ")", "id, content_nm"));
p.display();

%>