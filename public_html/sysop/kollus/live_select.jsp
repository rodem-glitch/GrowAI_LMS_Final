<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init_live.jsp" %><%

//폼입력
int pageNum = m.ri("page");

//폼체크
f.addElement("s_keyword", null, null);

//처리
Http http = new Http("https://api-live-kr.kollus.com/api/v1/live/service-accounts/malgn/channels?order=id_desc&per_page=20&live_status=all&shared_status=all&trashed=0&page=" + (pageNum > 0 ? pageNum : 1) + (!"".equals(m.rs("s_keyword")) ? "&keyword=" + m.rs("s_keyword") : ""));
//http.setDebug(out);
http.setHeader("Authorization", "Bearer " + SiteConfig.s("kollus_live_access_token"));
Json j = new Json(http.send("GET"));

//목록
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
p.setLayout("pop");
p.setBody("kollus.live_select");
p.setVar("p_title", "라이브 선택");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", meta.i("total"));
p.setVar("pagebar", pager.getPager());

p.display();

%>