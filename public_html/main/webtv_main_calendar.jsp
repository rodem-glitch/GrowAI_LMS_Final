<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
WebtvDao webtv = new WebtvDao();
LmCategoryDao category = new LmCategoryDao("webtv");
LmCategoryTargetDao categoryTarget = new LmCategoryTargetDao();
MCal mcal = new MCal();

//폼입력
int count = m.ri("cnt") > 0 ? m.ri("cnt") : 4;
boolean isMobile = "Y".equals(m.rs("is_mobile"));

//변수-현재
String today = m.time("yyyyMMdd");
int time = m.parseInt(m.time("HHmmss"));
String startWeek = m.time("yyyyMMdd", mcal.getWeekFirstDate(today));
String endWeek = m.time("yyyyMMdd", mcal.getWeekLastDate(today));

//목록-방송
DataSet list = webtv.query(
	" SELECT a.*, c.parent_id "
	+ " FROM " + webtv.table + " a "
	+ " INNER JOIN " + category.table + " c ON a.category_id = c.id AND c.status = 1 "
	+ " WHERE a.site_id = " + siteId + " AND a.open_date >= '" + startWeek + "000000' AND a.open_date <= '" + endWeek + "235959' "
	+ " AND a.display_yn = 'Y' AND a.status = 1 "
	+ ("recomm".equals(m.rs("mode")) ? " AND a.recomm_yn = 'Y' " : "")
	+ " ORDER BY a.open_date ASC, a.id ASC "
	, count
);
while(list.next()) {
	list.put("webtv_nm_conv", m.cutString(list.s("webtv_nm"), 56));
	list.put("subtitle_conv", m.nl2br(list.s("subtitle")));
	list.put("subtitle_conv2", m.nl2br(m.stripTags(list.s("subtitle"))));
	list.put("open_time", m.time("HH:mm", list.s("open_date")));
	list.put("open_day", m.time("yyyyMMdd", list.s("open_date")));
	list.put("open_day_conv", m.time(_message.get("format.datemonth.slash"), list.s("open_date")));
	list.put("open_block", 0 < m.diffDate("D", list.s("open_day"), today) || (0 == m.diffDate("D", list.s("open_day"), today) && time >= m.parseInt(m.time("HHmmss", list.s("open_date")))));
}

//출력
p.setLayout(null);
p.setBody("main.webtv_main_calendar");
p.setVar("p_title", "방송 편성표");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);

p.setVar("dir", !isMobile ? "webtv" : "mobile");
p.display();

%>