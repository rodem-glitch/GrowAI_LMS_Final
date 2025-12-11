<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(925, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
WebtvDao webtv = new WebtvDao();
WebtvLogDao webtvLog = new WebtvLogDao();
LmCategoryDao category = new LmCategoryDao("webtv");
MCal mcal = new MCal(10);

//날짜
String today = m.time("yyyyMMdd");
DataSet dinfo = new DataSet(); dinfo.addRow();
dinfo.put("sd", m.time("yyyy-MM-dd", today));
dinfo.put("ed", m.time("yyyy-MM-dd", today));
dinfo.put("sw", m.time("yyyy-MM-dd", mcal.getWeekFirstDate(today)));
dinfo.put("ew", m.time("yyyy-MM-dd", mcal.getWeekLastDate(today)));
dinfo.put("sm", m.time("yyyy-MM-01", today));
dinfo.put("em", m.time("yyyy-MM-dd", mcal.getMonthLastDate(today)));
dinfo.put("sy", m.time("yyyy-01-01", today));
dinfo.put("ey", m.time("yyyy-12-31", today));
dinfo.put("s3y", m.time("yyyy-01-01", m.addDate("Y", -2, today, "yyyyMMdd")));
dinfo.put("e3y", m.time("yyyy-12-31", today));

//폼입력
String sdate = m.rs("s_view_sdate", dinfo.s("sm"));
String edate = m.rs("s_view_edate", dinfo.s("em"));

//폼입력
f.addElement("s_view_sdate", sdate, "hname:'시청시작일'");
f.addElement("s_view_edate", edate, "hname:'시청종료일'");
f.addElement("s_open_sdate", null, null);
f.addElement("s_open_edate", null, null);
f.addElement("s_category", null, null);
f.addElement("s_display_yn", null, null);
f.addElement("s_status", null, null);

dinfo.put("sdate_conv", m.time("yyyy.MM.dd", sdate));
dinfo.put("edate_conv", m.time("yyyy.MM.dd", edate));

//카테고리
DataSet categories = category.getList(siteId);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(20000);
lm.setTable(
	webtvLog.table + " a "
	+ " INNER JOIN " + webtv.table + " w ON a.webtv_id = w.id AND w.site_id = " + siteId + " AND w.status != -1 "
	+ " LEFT JOIN " + category.table + " c ON w.category_id = c.id "
);
lm.setFields("w.*, c.category_nm, COUNT(*) view_cnt");
if(!"".equals(sdate)) lm.addWhere("a.reg_date >= '" + m.time("yyyyMMdd000000", sdate) + "'");
if(!"".equals(edate)) lm.addWhere("a.reg_date <= '" + m.time("yyyyMMdd235959", edate) + "'");
if(!"".equals(f.get("s_open_sdate"))) lm.addWhere("w.open_date >= '" + m.time("yyyyMMdd000000", f.get("s_open_sdate")) + "'");
if(!"".equals(f.get("s_open_edate"))) lm.addWhere("w.open_date <= '" + m.time("yyyyMMdd235959", f.get("s_open_edate")) + "'");
if(!"".equals(f.get("s_category"))) lm.addWhere("w.category_id IN ( '" + m.join("','", category.getChildNodes(f.get("s_category"))) + "' )");
lm.addSearch("w.display_yn", f.get("s_display_yn"));
lm.addSearch("w.status", f.get("s_status"));
//lm.addSearch("a.complete_yn", f.get("s_complete"));
lm.setGroupBy("a.webtv_id");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "view_cnt DESC, w.webtv_nm ASC");

//포멧팅
int sumTotalCount = 0;
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("category_nm", category.getTreeNames(list.i("category_id")));

	list.put("subtitle_conv", m.stripTags(list.s("subtitle")));

	list.put("open_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("open_date")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("log_reg_date")));
	list.put("view_cnt_conv", m.nf(list.i("view_cnt")));
	
	sumTotalCount += list.i("view_cnt");
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "방송별시청통계(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "open_date_conv=>방송일시", "category_nm=>방송카테고리", "id=>방송ID", "webtv_nm=>방송명", "subtitle_conv=>부제목", "view_cnt=>시청횟수" }, "방송별시청통계(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}


//출력
p.setBody("stat.webtv_stat");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("sum_total_count", m.nf(sumTotalCount));

p.setLoop("status_list", m.arr2loop(webtv.statusList));
p.setLoop("display_list", m.arr2loop(webtv.displayList));
p.setLoop("categories", categories);
p.setVar("date", dinfo);
p.display();

%>